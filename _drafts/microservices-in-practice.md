---
layout: post
published: true
title: microservices
summary: |
  tbd
---

@pedrocunha:
> I raised that point too, but it was agreed that it would be better to wrap
> these calls in this service in case we want to do anything different with them
> - we'll be doing the same with the property-search - @mezis can fill you in on
> the reasoning behind it.

In a word, microservices and compact concerns. In more words:

If the mobile app "talked" directly to the search service, you'd be faced with 2
equally bad choices:
- Make several calls from mobiles to the property APIs to get details about the
  properties (as the search service only returns IDs). Terrible for performance.
- Change the search service to know about, and return, property details; add
  Messagepack support. Terrible for performance _and_ for separation of concerns
  — services should know as little as possible about the concepts they aren't
  the authority for\*.

I believe this is a pattern — we'll be faced with similar choices, and we
actually have in a few places (c.f. existing mobile APIs). If so, it makes sense
to add a "middleman service" (this repo). Its concern\*\* could be summarized as
"adapt internal APIs to re-expose them in a mobile-friendly manner", which will
typically include, in order of importance:

- Convert 1 "mobile" API call into N "internal" / RESTful internal calls (c.f.
  search + get properties example);
- Cache calls to internal APIs;
- Add mobile-friendly encoding (Gzipped Messagepack);
- Cache reponses (ideally in a CDN)

It's also been discussed whether the "know about devices" concern (which lives
in the monorail at the moment) should move to this service. I do think it should
move it _out_ of the monorail, but I'm still hesitant between:

- expanding the scope if this service (`mobile-app-api`), which is generally
  bad, but then the concern is still congruent;
- moving it to another internal service (and re-expose it through this service).

Tell me if this helps :)

\* The search service is not responsible for any concept so far, and will be
reponsible for _price of a stay_ down the line.

\*\* incidentally, this should be mentionned on the (missing) README, along with
setup instructions and the first APIs... @matthutchinson :wink: 
