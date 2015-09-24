---
layout: post
published: true
title: Timing Rack Middlewares with metaprogramming, recursive monkey-patching, and a sprinkle of statistics
author: Julien Letessier
summary: |
  Analysing performance of your Rails or Sinatra is easy enough with New Relic,
  but figuring out whether the soft outer shell of your stack is under-performing 
  is more of a challenge. We've written
  [rack-timer](https://github.com/mezis/rack-timer#rack-timer) to figure things
  out.
---

_This article was crosss-posted from the HouseTrip [engineering blog](http://dev.housetrip.com/)._

The most typical tool Ruby web stacks use to monitor runtime performance is New
Relic. It does a great job at spotting what happens inside transaction, which
database queries are slow, etc. It also reports on something called _queue
time_, as the infamous green slab at the bottom of its graphs.

[Misleadingly](http://blog.newrelic.com/2013/01/22/understanding-new-relic-queuing/),
queue time it not request queuing: it's the delay between when a requests hits
your web frontend (Apache, NGinx) and the beginning of your _action_. Thus, it
includes three things:

- time spent in your HTTP dispatcher (Passenger, Unicorn)
- time spent in your Rack middlewares
- time spent in `before/after_filters` (if using Rails).

We had a hunch that something awry was going on in the outer layers of our
stack, and neither New Relic nor any beautiful gem gave us any intel.

<figure>
  <img width="550" src="/public/2014-03-rack-timer/2A2y120D460U.png"/>
  <figcaption>The infamous green "queue time"</figcaption>
</figure>

[rack-timer](https://github.com/mezis/rack-timer#rack-timer) aims at solving
that by providing timings for dispatch time and middlewares.

## Inside Rack-Timer

It works in a borg-like way: add it to the top of your middleware stack (if
using Rails, even before `Rack::Lock`), and it will "assimilate" every other
middleware by injecting its code recursively into every other middleware.

The `RackTimer::Middleware` initializer looks like this:

{% highlight ruby %}
  def initialize(app)
    @app = app
    self.extend(Borg)
  end
{% endhighlight %}

Starting the chain reaction, it injects the `Borg` in itself; then once part of
the collective (simplified code):

{% highlight ruby %}
  module Borg
    def self.extended(object)
      object.singleton_class.class_eval do
        alias_method :call_without_timing, :call
        alias_method :call, :call_with_timing
      end

      object.instance_eval do
        recursive_borg
      end
    end

    def recursive_borg
      @app.extend(Borg)
    end
{% endhighlight %}

The `Borg` wraps the `call` method of each middleware it's injected into with
time logging, the injects itself in the next middleware down the stack
(conventionally, `@app`).

At runtime, the `call` wrappers will transparently call the originally `call`
then output timing information.

## Outcomes

Within our biggest application, we let 40 out of 520 workers work with the `Borg` in
place until they'd collected information about 10,000 requests—enough to provide
us with statistically significant data.

With `rack-timer` defaults, logs go to standard error, i.e. Apache's
`error.log`. We grabbed those, grep'd for the timer's output, whipped some
`sed(1)` magic along the lines of

    $ bzcat error.web[1-4].bz2 | \
      grep '^\[rack-timer\]' | \
      sed -e 's/^.rack-timer. //; s/ took /,/; s/ us$//' \
      > middlewares.csv

and voilà, raw data ready to be digested. Good old Excel then graphed the
middleware timings for us:

<figure>
  <img width="550" src="/public/2014-03-rack-timer/460a3z060F3B.png"/>
  <figcaption>Middleware timings</figcaption>
</figure>

The reason we graph both median and mean is that the latter is sensitive to
outliers, whereas the median is a "robust metric". A significant discrepancy
between the two usually hints either at a skewed, non-normal distribution, or
more typically presence of extreme outlier.

None of this here—not only the middleware all respond consistently, but the
aggregate median time spent in middlewares is (despite their number) a low
7.5ms.

Note the left-most pair of bars in that graph—that's the tail of the middleware
chain, i.e. the application itself (including filters).

Moving one to the queue timings with another handful of `sed` magic. This time
Excel doesn't cut it, but [R](http://www.r-project.org/) is probably an old
friend to anyone serious with performance analysis, and stats in general.

Distribution of the queueing timings used to look like this:

<figure>
  <img width="550" src="/public/2014-03-rack-timer/2D2336390628.png"/>
  <figcaption>(horizontally: log10 of the queuing time in microseconds, ie. 3 is 1ms and 6 is 1 second)</figcaption>
</figure>


This is clearly bimodal: the left mode (clustered around 1ms) is expected.
Passenger does need to do _some_ work do move requests around, and 1ms is fine.

The second mode is much more worrisome: its overall area (i.e. the overall number
of requests spent in that failure mode) is about half of the total, and it's
fairly progressive (not a nice bell curve at all), hinting at some kind of
step/non-linear phenomenon.

The conclusion was that something what causing progressively more queuing in some cases.

That's when we remembered that

1. We'd added out-of-band garbage collection to relieve the Ruby VM back in the
   1.8 days
2. We'd recently upgraded Passenger to 3.0+

It turned out our out-of-band garbage collection hack (based on
[rack_after_reply](https://github.com/oggy/rack_after_reply)) was no longer
compatible with Passenger: what used to be run out-of-band was now run _in-band_
with th _next_ request on a particular worker.

Removing the out-of-band garbage collection solved the issue:

<figure>
  <img width="550" src="/public/2014-03-rack-timer/3z0V40291P46.png"/>
</figure>

On top of that we've cut our average response time by a further 15 to 20%, and
obviously suffer less from the spikiness in response time due to random GC hits.

And finally, having a proper excuse to write an arguably dangerous
metaprogramming / recursive monkey-patching combo was fun!

