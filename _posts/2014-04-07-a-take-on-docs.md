---
layout: post
published: true
title: Document and comment code? Or don't?
summary: |
  The stance on documentation in the Ruby community seems to oscillate between
  "RDoc the hell out of it" or "nah, the code (or the test suite) is the
  documentation".

  We think both are untrue, and have a pragmatic middle ground: "documentation"
  _per se_ exists mostly under the skullcaps of team members, but some things do
  need minimal documentation.
---


I decided to try to write it down properly after receiving this email from
[Nilan](https://twitter.com/nilanp):

> Hey Julien - 
> <br/>
> One of the start ups I advise at the moment is going through scaling hell -
> (i.e. adding a load of developers to a monolithic code base)
> <br/>
> As they ramp up devs (i.e. doubling the number of devs) - they are seriously
> considering spending a lot of time documenting their code base - this smells
> like a bad idea - my general steer would be to focus that time on writing good
> well commented code and ensuring you have a well documented pull request
> process.
> <br/>
> **Would you ever advise a startup to write documentation ?  Sorry if this is an
> open ended question**

I'd never advise anyone to write detailed documentation. That typically falls
out of sync with codebases quickly unless you're really anal about it, and can
afford the enormous time wastage.

Well designed code doesn't need much documentation, but in my opinion, it does
require at least these basics.


### Guidelines

There should be established and respected
[guidelines](http://github.com/HouseTrip/guidelines) and standards. At HouseTrip
we enforce those [through code
reviews](http://dev.housetrip.com/2014/01/22/deal-with-pull-requests-faster-and-easier-with-trailer/).

This reduces the need for documentation, as having consistent tools and ways to
use them acts as a _lingua franca_.


### Naming

Naming in the codebase should be excellent. Classes, methods, project names
should map closely to the domain. Naming should be debated.

Like the above, good naming avoids misunderstandings with your future selves
(and teammates). Anyone who's worked with me knows I can stall progress on a
project at the whiteboarding stage until we nail how we're going to name things
(URL resources, classes, repositories, etc.) and I firmly believe that's well
invested time.


### READMEs

Each project (repository) should have a [good
README](http://dev.housetrip.com/2013/11/29/good-readmes/), stating at a minimum
the project's manifesto (what are we trying to solve, what are the principles we
adhere to), how to install it and play with it, how to deploy it, basics of its
(external) API, and a set of block diagrams giving an overview of the internal
architecture. Here’s a [possible
example](https://github.com/HouseTrip/routemaster).

Typically, we start projects with the README. We do our best not to discuss
internals, architecture, or even what technology we'll use until that's written
down. It's normally our first commit in any repo.


### Smart comments

Any part of a method/function that requires some thought, has anything hacky or
contorted, should be commented.

My motto is "if you have to think twice before writing it, it needs a comment".

Simply put, if you had to take time to write your head around it, despite having
most of the domain in mind already, your future future self (or others) are
likely to be unable to make heads or tails of it. No amount of specs are going
to save you.

The key thing to remember here is that code gets written once, edited a few
times, and read countless times over the lifecycle of a software product---all
that by different people if it's successful.


### Brain storage

No single engineer should ever be the only one with intimate knowledge of part
of the codebase.

This is, incidentally, an argument to actively _limit_ the number of different
technologies in use in a company, otherwise that goal is much harder to achieve
(amongst other issues). This also means you can't have less than two people
coding on any project.

Pair programming, shuffling teams, and leaning on long-time team members for
mentoring, and importantly retention are key here.


#### Conclusion

Yes, documentation is important. But where documentation was simple in the
waterfall days, the fat stack of paper---or the fat stack of RDoc---doesn't
quite cut it anymore.

A combination of well-thought, minimal starter docs and trusting in the brain
power of the collective is a means of documenting code that we think maps better
to an iterative, decentralized practice of software engineering.


Agree? Disagree? I'd love to hear your thoughts - I'm
[@mezis_fr](https://twitter.com/mezis_fr).

