---
layout: post
published: true
title: "RESTful -and- fast: Representational State Notification"
summary: |
  Adding lightweight state change notifications to the REST architecture style
  can alleviate some of its performance limitations, without violating its
  principles. It also obviates the temptation to revert from a RESTful, domain-
  centric resource oriented architecture to an RPC-style, function-centric
  microservice architecture.

  If you care mostly about the solution, feel free to skip to the section
  about [Routemaster](#introducing-routemaster). The beginning of the article
  presents the concepts and rationale.
---

_This article was cross-posted from the [HouseTrip dev
blog](http://dev.housetrip.com/2014/09/20/resn-routemaster/)._


## The many-requests problem

Let's take a classical performance problem in a resource-oriented
architecture.

We're building a façade application that serves mobile apps, transforming
aggregate calls (as a mobile app must limit the number of HTTP requests it
makes) into an number of RESTful calls. It's backed by 3 RESTful
applications: a search engine, an photo repository, and a products
repository.

                                       ┌────────────┐
                                    ┌─>│ products   │
                                    │  └────────────┘
    ┌────────────┐   ┌────────────┐ │  ┌────────────┐
    │ mobile app │──>│ façade app │─┼─>│ search     │
    └────────────┘   └────────────┘ │  └────────────┘
                                    │  ┌────────────┐
                                    └─>│ photos     │
                                       └────────────┘

When a user performs a search on the native app, it makes 1 request to the
façade to get a page of search results (20 entries). The façade must make
one call to the search engine; follow the hypermedia links to make 20 calls
for the 20 products; follow _their_ links to make 20 requests for 20 photos.

This results in a conservative 41 HTTP requests (in 3 sequential batches) to
serve a simple user query; the use case is simplified, so the real situation
is actually worse.

Without parallelism, the best case scenario is a **2s latency** for users
(assuming 50ms response time for each application), which is unacceptable.

Even when introducing 10x request concurrency and server-side caching on
each application, this theoretical problem would yield a minimum 250ms
latency, which isn't fantastic (and has a high processing cost).

In more complex scenarios, with tens of applications and several layers, this
problem can explode.


## REST promises and shortcomings

[RESTful][restful] distributed architectures, especially when combined with
[Domain-driven][ddd] design and patterns like [CQRS][cqrs], can help a
software system to reach for holy grails of web engineering:

- Granular software **scalability**: parts of the system can be scaled up or out
  according to demand, thus both permitting scale and limiting costs
- Team **scalability**: a component system with well-defined, standardised
  boundaries can be upgraded piecemeal. It becomes realistic to have multiple
  groups of engineers maintaining, improving, or otherwise changing components
  locally, without the need for release engineering bottlenecks.

This type of approach is in its infancy, underlined by typical organisational
failures (see for instance _[Failing microservices][failing-microservices]_) and
a higher requirement for strong guidelines.

It's also made difficult by the lack of mature tools a libraries, unlike the
strong support for SOA architectures that has existed since the mid-90s; and the
confusion between the two approaches.

### REST/ROA versus RPC/SOA

I'd like to briefly shed some light on what seems to be a common
[confusion](http://martinfowler.com/bliki/ServiceOrientedAmbiguity.html)
in the web engineering community: in my opinion, there is no such thing as a
RESTful SOA (service-oriented architecture). At least, not if the SOA in
question does anything like remote procedure calls.

REST was introduced in the context of the Web and Hypermedia, and supports
[ROA][roa] (Resource-Oriented Architectures). Conversely, SOA emerged to design
sunk systems (backends), and while their external (consumer-facing) interface
may be RESTful, services usually communicate using RPC-style semantics (possibly
over HTTP, e.g. using JSON-RPC, which adds to the confusion).

Martin Fowler's [reference article][fowler-micros] on Microservices seems
to suggest to express, and split the domain in terms of functions, not concepts.
Each service is responsible for a "data transformation" (he mentions ["dumb"
pipes][dumb-pipes]) and "decentralizing decisions about conceptual models". He
actually uses the term "RESTish", not "RESTful" to describe the communication
between services: they can still use HTTP as a transport, but they're about
verbs (functions), not nouns (concepts/resources).

We think that SOA is incompatible with Domain-driven design, REST as an
architecture style, and therefore ROA.

This is not to say that SOA is "bad" — [others][hailo] have followed a
"microservices" SOA approach and implemented very successful and impressive
RabbitMQ-based, function-centric approaches to distributed Web systems.  (albeit
at the cost of introducing of an extra interoperation protocol). One of the
tenets of REST is that HTTP is "enough".

In our opinion, any domains can be expressed in terms of CRUD operations on
resources — although that does require surfacing some actions ("services") as
resources.  For instance, the canonical example of a "friendship service" in the
[service layer](http://martinfowler.com/eaaCatalog/serviceLayer.html) of an
application can be surfaced as a "friendship" resource in an API, rather than as
a "add a friend" remote call to a "friendship lifecycle" service.


### Fallacies of REST

Any distributed system has known pitfalls and caveats. This applies to SOA, ROA,
and of course to the REST architecture style specifically.

Some are known as the [fallacies of distributed computing][fallacies] (which
[hold true](http://www.cse.unsw.edu.au/~cs9243/14s1/papers/fallacies.pdf), two
decades in); in particular, the implicit assumption that:

- Latency is zero
- Bandwidth is infinite

While we don't offer to tackle the design difficulties of [eventual
consistency][eventual-con] in typical distributed systems, we believe the
latency issue (which has a user experience cost) can be mitigated at the expense
of bandwidth (which "only" costs money).

REST [mandates caching][rest-caching], as a key component of the architecture,
through the standard HTTP mechanism (`Cache-Control` headers for client-side
caching, `ETag` headers for server-side caching).

Unfortunately, this leaves ROA designers with two options:

- Using `Etag`: low client memory, low bandwidth, high consistency, **high
  latency**.
- Using `Cache-Control`: high client memory, low bandwidth, low consistency, low
  latency.

Heroku has a [good
intro](https://devcenter.heroku.com/articles/increasing-application-performance-with-http-cache-headers)
on caching with HTTP.
It's basically a game of: high consistency, low latency, pick one.


## Representational state notification

Event buses are a common tool to implement the [reactor
pattern](http://en.wikipedia.org/wiki/Reactor_pattern) or the [pub-sub
pattern](http://en.wikipedia.org/wiki/Publish%E2%80%93subscribe_pattern).  For
instance, Ruby engineers will be familiar with asynchronous buses like
[Celluloid](http://celluloid.io/), or the defunct
[EventMachine](https://github.com/eventmachine/eventmachine); or synchronous
buses like [wisper](https://github.com/krisleech/wisper).

We believe these patterns to be valuable at the inter-application level. And
indeed, numerous services (e.g. [Pusher](https://pusher.com/)), web technologies
([Server-sent events](http://en.wikipedia.org/wiki/Server-sent_events)), even
databases ([Redis pub-sub](http://redis.io/topics/pubsub)) have a take on
supporting these patterns.

However, there is [architectural
mismatch](http://dl.acm.org/citation.cfm?doid=225014.225031) between those
options and a RESTful, hypermedia, resource-oriented architecture.

### Introducing Routemaster

To close this gap, we've built [Routemaster][rm], an opinionated event bus over
HTTP, supporting event-driven / representational state notification
architectures.

Routemaster is designed on purpose to not support RPC-style architectures, for
instance by severely limiting payload contents: the _only_ events that the bus
supports are notifications of **CRUD operations** on resources (in other words,
events about a change in their representations). The _only_ information an
event carries are the type of event, the name of the domain concept, and the
authoritative URI of the resource.

_Don't call us, we'll call you_: events are received and delivered over HTTP so
that the bus itself can scale to easily process a higher or lower, inbound or
outbound throughput of events with consistent latency.

Routemaster aims to dispatch events with a median latency in the 50-100ms range,
with no practical upper limit on throughput. Importantly, it's "just" another
application itself, which means that its capacity can be managed and scaled just
like any other application in our federation of apps.


### Fixing the many-calls problem

Fixing this problem without changing the structure of our application federation
(as presented in the first section) or the architecture style (REST, Hypermedia) can
seem straightforward: we need to _not_ make this many calls.  This means that the
consumer application (the "façade" in our example) needs to have closer access
to resource representations; in other words, it needs an application-local
cache... which needs to be fresh, for fear of making the [eventual
consistency][eventual-con] problem unmanageable.

Routemaster provides us with an elegant solution: it can notify a consumer
application every single time a resource is modified (or created, or destroyed).

Resource providers can now forego client-side caching headers (`Cache-Control`)
and notify the bus whenever representations change.

Resource consumers can subscribe to the bus, and invalidate their cache whenever
notified; between invalidations, they're free to cache representations forever.

We provide the
[routemaster-client](https://github.com/HouseTrip/routemaster-client) library to
emit events and set up subscriptions, and
[routemaster-drain](https://github.com/HouseTrip/routemaster-drain) to receive
events and automate caching and cache invalidation.

The bandwidth efficiency of this approach can be tuned — from purely on-demand
caching to full preemptive caching on state change notifications. On the far end
of the scale, it entirely solves the latency issue, bringing us back to a
performance comparable to monolithic approaches, without the drawbacks.

In other words (and probably being dangerously pretentious about it):

> There are two hard things in computer science: cache invalidation, naming
> things, and off-by-one errors.

Time will tell, but we think we've driven a nail into the coffin of the first
one.

Tell us what you think!



[cqrs]: http://martinfowler.com/bliki/CQRS.html
[ddd]: http://en.wikipedia.org/wiki/Domain-driven_design
[dumb-pipes]: http://martinfowler.com/articles/microservices.html#SmartEndpointsAndDumbPipes
[eventual-con]: http://en.wikipedia.org/wiki/Eventual_consistency
[failing-microservices]: http://www.infoq.com/news/2014/08/failing-microservices
[fallacies]: http://en.wikipedia.org/wiki/Fallacies_of_Distributed_Computing
[fowler-micros]: http://martinfowler.com/articles/microservices.html
[hailo]: https://speakerdeck.com/mattheath/youre-good-to-go
[rest-caching]: http://www.ics.uci.edu/~fielding/pubs/dissertation/rest_arch_style.htm#sec_5_1_4
[restful]: http://en.wikipedia.org/wiki/Representational_state_transfer
[rm]: http://github.com/housetrip/routemaster#routemaster
[roa]: http://en.wikipedia.org/wiki/Resource-oriented_architecture

