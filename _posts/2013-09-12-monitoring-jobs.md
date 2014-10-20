---
layout: post
title: Monitoring backend services, a tale of delays and dogs
published: true
tags: ruby performance architecture
summary:  |
  We wanted to share how we evolved our asynchronous job processing over the past year. The TL,DR of our findings are:

  - Using [DelayedJob](https://github.com/collectiveidea/delayed_job) for
    queueing/running asynchronous tasks scales well, in terms of throughput,
    variety of jobs, and cost of maintenance.
  - This does require backing it with
    [Mongo](https://github.com/collectiveidea/delayed_job_mongoid) (for high
    throughput) and keeping it agnostic to the type of jobs it's running
    (for low maintenance).
  - We found it more practical to manage a limited number of queues based on
    urgency bands, rather thand trying to prioritise individual jobs based
    on (perceived) importance.
  - Good monitoring is imperative, but trivial to achieve with
    [statsd](https://github.com/etsy/statsd/) and a good frontend/alerter
    like [Datadog](http://www.datadoghq.com).

---

*This was reposted from [HouseTrip's developer blog](http://dev.housetrip.com).*


## Preface

A web application often has to perform tasks _asynchronously_ with respect
to user input, that is, outside of the request cycle.

Typically this includes sending emails, but can also be updating various
kinds of counters, tracking, priming cache, scaling uploaded images, and so
on.

In some cases the user is a developer, or a scheduler in the system, running
some [Rake](https://en.wikipedia.org/wiki/Rake_(software)) task but not caring to wait for the
result.

In all cases, to run jobs asynchronously, you will need two subsystems:

- one or more **queues**, which holds **jobs**, a representation of the
  pending atoms of work to be done;

- one or more **workers**, which pulls jobs from the queues and execute the
  corresponding work.

In [Rubyland](https://www.ruby-toolbox.com/categories/Background_Jobs) there
is more than one option to run this; the most classic are certainly
[DelayedJob](https://github.com/collectiveidea/delayed_job),
[Resque](https://github.com/resque/resque), and
[Sidekiq](http://sidekiq.org).


## A quiet life in Rubyland

At HouseTrip, one of our guidelines can be phrased as

> if you don't need it now, run it async. don't make the user wait.

We've used DelayedJobs for quite a while; originally with the (default)
ActiveRecord-backed queue, and switched to a Mongo-backed queue when the
going got tough (somewhere north of 1 job/second), and ActiveRecord (and the
SQL database behind it) couldn't take it anymore.

Things were as simple as "delaying" method calls:

{% highlight ruby %}
WelcomeMailer.delay.deliver_welcome_email(current_user)
{% endhighlight %}

Because some jobs are more urgent than others, we started using DelayedJobs
[priorities](http://rubydoc.info/gems/delayed_job/#Queuing_Jobs): each type
of job would be assigned an integer _priority_ from 0 to 999, and classified
jobs by their relative importance as we went.
So whenever a new job was introduced, "job X is more important than Y"
became "job X should have a lower _priority_ than Y" (yes, it's backwards,
but that's how [UNIX decided it would be](https://en.wikipedia.org/wiki/Nice_(Unix))
a long while back).

What priorities really define is multiple, independent queues. The workers
will always pick up work from a lower-priority queue before other work.
Other than this ordering, the workers are agnostic: they accept work
from all queues.

It quickly becomes natural to do this:

{% highlight ruby %}
WelcomeMailer.delay(priority:1).deliver_email(current_user)
UnsubscribeMailer.delay(priority:999).deliver_email(current_user)
{% endhighlight %}

It's served us well, until a little over a year ago.


## You're not in Kansas anymore

But then the going got tougher. Our main Rails application had a _lot_ of
stuff to run asynchronously, which translates in a fairly congested queue (2
jobs/second average, peaks at 20 jobs/second).

We had lots of different types of jobs (dozens).

And what was bound to happen, happened: jobs that was supposed to run
didn't, when jobs did run and when they didn't was a bit of a mystery,
computers burst into flames, and product manager heads started spinning.


## Three little piggies

Lack of trust in our good old friend DelayedJobs developed, and the more
adventurous amongst us started suggesting solutions.

— *Let's put my stuff at a high priority*, the first one said. *I was told
  it should always be done as soon as possible.*.

— *Let's use Sidekiq*, the second one said. *All the cool cats are using it.*
  
— *I know,* said the third one. *Let's have a dedicated queue and set of
  workers just for my job, since it's, like, so very important!*


## Huffin' and puffin'

Unfortunately, I believe those are all coping mechanisms.

The first piggie is confusing _importance_ and _urgency_ of a job.
Importance is almost impossible to define because it's relative;
different stakeholders will have different views, and importance may well
vary over time as well, making it a maintenance nightmare. As I pointed out
earlier, this was our original mistake—creating different queues
(priorities) by importance.

The second piggie thinks there's a silver bullet. In computing, there rarely
is; and when we suggested this, we were just being the victims of hearsay
and non-comparable experiences. Sidekiq, for instance, has a few extra
features (notification of [batch
completion](https://github.com/mperham/sidekiq/wiki/Batches), for instance);
but in our scenario it'd be a 1:1 replacement for DelayedJobs. So Sidekiq
won't solve our issue—it'll just give us lower job latency, and possibly
better job throughput, mainly because it's Redis-backed.

The third piggie is less wrong than the other first two. Having a dedicated
queue and workers for one or more job types (i.e. dedicated infrastructure)
can, indeed, increase reliability. What he might be missing is that he's
trading that for increased cost of maintenance (another part of the stack
now needs management and scaling), and that this rationale can be repeated
_ad nauseam_: everything's important, so everything should get dedicated
resources.

By that last logic, we'd have dedicated web stacks (dynos if you're running
on Heroku) for every page, so we can micromanage latency on a page-by-page
basis.


## Back on the Yellow Brick Road

Taking a step back, the root of the problem is really what we've stated
concerning the first piggie: we tend to confuse _importance_ and _urgency_
of asynchronous tasks.

So we've decided to turn around. Instead of dealing with the impossible task
of pitting each type of job against every other one, we ask ourselves (and
our product people): how urgent is this job? In the sense, **by when should
it complete?**.

Implementing this turns out to be simple. We've added some naming sugar:

{% highlight ruby %}
module Delayed::Priority
  REALTIME = 0
  MINUTES  = 25
  HOUR     = 50
  DAY      = 75
  WEEK     = 100
end
{% endhighlight %}

and schedule jobs using named urgency bands:

{% highlight ruby %}
RememberTheMilkService.new
.delay(priority: Delayed::Priority::DAY)
.run
{% endhighlight %}

Our DelayedJob-based queue/dispatch subsystem now makes a simple promise: if
you give me a job with `HOUR` priority, I'll start running it within the
next 60 minutes. It's a **promise of timely execution**.

At this point it's just a promise; something extra will be needed to enforce
it, as if someone shoves thousands of jobs in the `REALTIME` queue and you
have only one measly worker, they're not going to run magically.

Switching to this takes a bit of discipline but works. We just have to
fight the occasional urge to confuse `REALTIME` with "it's really that
important". We reserve `REALTIME` job jobs that should be completed by the
time a user of the web frontend issues their next request.

The lesson we learned is failry simple:

> Urgency-based scheduling works because there is a rational answer to the
> urgency question, but only emotive answers to importance.


## Last steps to Oz

Urgency bands helped us manage a growing number of jobs and job types and
still have jobs (mostly) delivered in a timely fashion... until it didn't.
Again, some jobs ran late, and confusion and despair ensued!

While we still believed "urgency over importance" was the way to go, we were
missing a key piece of the puzzle: we hadn't addressed the **lack of
confidence** developers had in whether the promise of timely execution would
be kept.

The problem being trust, the obvious solution is transparency and reason. We
are breaking the promise as soon as a job gets started after its queue's
time-promise (5 minutes, 1 hour, etc.) has elapsed since it was scheduled.

We chose to define **queue staleness** as the age of the oldest un-executed
scheduled job on a given queue, divided by the queue's promise. When this
value is greater than 1, the queue is stale.

For instance, if the oldest job on the `DAY` queue is 25 hours old, the
staleness is 25/24 ≈ 1.04.

Whenever any queue is stale, the queue/run subsystem is over capacity, and
you need more workers.

When none of the queues are stale, it's running under capacity, and some of your workers are idling.

Implementing this turned out to be quite easy:

{% highlight ruby %}
schedule.every('10s') do
  now = Time.now.utc

  Delayed::Priority.constants.each do |priority_name|
    priority = "Delayed::Priority::#{priority_name}".constantize

    earliest_job = Delayed::Job
      .where(:priority => type, :attempts => 0, :locked_by => nil)
      .fields(:created_at)
      .sort(:created_at)
      .limit(1).first
    staleness = earliest_job ? 
      earliest_job[:created_at].getutc.to_i : 
      0

    STATSD.gauge 'dj.staleness', staleness,
      tags: ["queue:#{priority_name}"]
  end
end
{% endhighlight %}

`STATSD` being a Statsd client, in our case courtesy of the datadog gem
(code simplified for the sake of the discussion).

The last bit being cute graphs and setting up alerts, which probably took 15
minutes overall. Here's a few of the staleness graphs:

<figure>
  <img src="/public/2013-09-12-staleness.png" class="dc-picture" alt="Staleness over time"/>
</figure>

All of us get an email alert if any of these go over 1.

This kind of monitoring is obviously an ops's wet dream: volume of jobs per
queue, throughput of jobs, failure rates... all become easy to monitor, and
help answer other questions. The most useful graphs are the **staleness**
graphs as they allow for capacity planning, which is crucial for a fast
growing app.


## They lived happily and had many little jobs

Our current setup lets us run quite a few jobs (1M/day). They're run mostly
timely, we do have a few staleness spikes around nightly events (which will
eventually need to be refactored).

Importantly, we now know when we're underperforming, as we get alerts when
we need more DelayedJob worker capacity.


## Further work

Working on our queue/run backend has given the team a taste of monitoring
beyond the usual [Nagios](http://www.nagios.org)-style server monitoring and the NewRelic-style
frontend application monitoring.

We're thinking to start reporting on a "job
[Apdex](https://newrelic.com/docs/site/apdex-measuring-user-satisfaction)"
metric for jobs to reflect how timely jobs are typicaly run (we'll find
another name if Apdex is a trademark).

To be able to action Job Apdex, we're considering auto-scaling our job
execution backend.

Finally, we're still very much considering a switch to a lower-latency
queue/run platform like Resque. But for know, we've gotten rid of the main
pain points.

Have fun with jobs!


_Update (Oct. 2014):_ Fixes dead links.

