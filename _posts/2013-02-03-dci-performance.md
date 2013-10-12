--- 
layout: post
title: DCI in Ruby is not broken
published: true
tags: ruby performance design
summary: |
  Applying the DCI pattern by using Ruby's dynamic object metaclass manipulation, also known as `Object#extend`, has been getting heat.
  Turns out it's quite all right.
  
  This article aims to show that object delegation does not have a significant performance advantage over object extension, with the notable exception of MRI Ruby 1.9.2. And delegation actually much, much slower in 1.8.
--- 


> **TL;DR** (edited): As emerged in the comments below, there's a potentially enormous [performance hit](https://gist.github.com/mezis/5595024) to using `#extend` as each call flushes the method cache for your whole current Ruby VM, up to and including in Ruby 2.0.0.
> Of course YMMV.

Orignal **TL;DR**: Unless you're Ruby 1.9.2, feel free to implement DCI or runtime traits using `#extend` as the performance hit is absent or small compared to other alternatives.

One of my [colleagues](https://github.com/hubb) recently pointed me at possible issues with the way we usually implement runtime object traits, as part of the [decorator pattern](http://en.wikipedia.org/wiki/Decorator_pattern) or [DCI](http://en.wikipedia.org/wiki/Data,_Context,_and_Interaction).

Tony Arcieri states that [DCI in Ruby is completely broken](http://tonyarcieri.com/dci-in-ruby-is-completely-broken), and I beg to differ.
Hopefully he doesn't mind and this addition to his work will convince him!

The author did some valid benchmarking, pointing out that using `#extend` can slow down method calls by several orders of magnitude, and proceeds to point us at Evan Light's [article](http://evan.tiggerpalace.com/articles/2011/11/24/dci-that-respects-the-method-cache/) on using delagation to implement runtime traits.

The problem is that, in my humble opinion, the benchmark he proposes is

- flawed (it only compares raw method calling with `#extend` traits, not with an alternate implementation), and
- incomplete (several mainstream Ruby versions, and memory usage, are ignored).

What's worse, it seems that the author inadvertently benchmark the *worst* RVM for this particular scenario.
The following provides a more complete benchmark to show the situation is note quite as black and white, and depends on

- the RVM you're using (make and version); and
- what method calls you're issuing (base class method or trait method).


### Traits using `#extend`

The way we typically do this uses Ruby's `Object#extend`:

    class User
      def name ...
    end

    module User::Scorable
      def scammer?
        false
      end
    end

    class Admin::Police::ScorableUserController
      def show
        @scorable_user = User.find(...).extend(User::Scorable)
      end
    end

    # in view
    @scorable_user.scammer?

In itself, this approach is nicely lightweight, and simple, although it probably won't quite satisfy the OO purists out there (Java, I'm looking at you).
The only thing I don't like really is the risk of clashing method names that Ruby's completely silent about.


### Traits using `SimpleDelegator`

Here's how we'd do the same thing with delegation:

    class User::Scorable < SimpleDelegator
      def scammer?
        false
      end
    end

    class Admin::Police::ScorableUserController
      def show
        @scorable_user = User::Scorable.new(User.find(...))
      end
    end

    # in view
    @scorable_user.scammer?

Not much more complex, until you add more than one trait, but that debate's out of scope here :)


### Static traits

For the sake of completeness, a final option to implement traits is to make them static using `#include` (thus bloating you class's namespace):

    module User::Scorable
      def scammer?
        false
      end

      User.send(:include, self)
    end

    class Admin::Police::ScorableUserController
      def show
        @scorable_user = User.find(...)
      end
    end

    # in view
    @scorable_user.scammer?


### Benchmarks

Down to the issue.

When calling methods of the base class (e.g. `@scorable_user.name` in the example above),
in 1.8.x MRIs including REE, extension is riduculously faster than delegation.
In 1.9.2 MRIs, delegation is now 600% faster, hence the point made in Tony's original article.
But in 1.9.3, it's **only 20% faster**.

With JRuby the performance gap is smaller, but extension consistenly faster. Rubinius behaves like 1.8 MRIs.

![Calls/second to base method](/public/2013-02-03-dci-performance/cpu-base.png)

When calling trait methods (e.g. `@scorable_user.scammer?` in the example above), the performance is roughly the same than above for 1.8 MRIs, JRuby, and Rubinius.
Note that the figures are exactly the same in all cases with overriden/masqueraded methods (which is why I didn't incude the graphs; see appendix for details).

MRI 1.9.2 exhibits an order-of-magnitude difference in favour of delegation.
However, the gap closes with 1.9.3, where the gap drops to a factor of two still in favour of delegation.

![Calls/second to trait method](/public/2013-02-03-dci-performance/cpu-trait.png)

Memory-wise, there seems to be a penalty to use delegation for all Rubies, especially the 1.8 series:

![Memory usage, calls to base method](/public/2013-02-03-dci-performance/mem-base.png)

![Memory usage, calls to trait method](/public/2013-02-03-dci-performance/mem-trait.png)



### Appendix: Reproducing the results

I ran this from a clean user account on my MacBookAir5,2.

If you want to reproduce these results, here's the [benchmark script](/public/2013-02-03-dci-performance/bench.rb) and the [shell driver](/public/2013-02-03-dci-performance/bench.sh). Make sure your machine is disconnected from the internet to avoid spurious processes from running; you'll also need [rbenv](http://github.com/sstephenson/rbenv/) and quite a few Rubies installed of course.

The raw data and the graphs are in [this Numbers.app file](/public/2013-02-03-dci-performance/bench.numbers).


### Conclusion

Pretty much stated in the article summary. My suggestion: stick with `#extend` if you're using it and you like it, although in some cases refactoring to use delegation may give you a small performance boost.

Think I'm right? Think my logic is crappy? Comment below...

