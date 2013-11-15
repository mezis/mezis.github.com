---
layout: post
title: Using data tiering to squeeze scale out of SQL
published: true
summary: |
  As traffic grows, some of the data structures our application has to
  manipulate gets contended. Ours is an unusual, but effective solution: segregate data into read-mostly and write-mostly.

  Read on for the nitty gritty.

---

*This was reposted from [HouseTrip's developer blog](http://dev.housetrip.com).*

As traffic grows, some of the data structures our application has to
manipulate gets contended. Ours is an unusual, but effective solution: segregate data into read-mostly and write-mostly.

I'll use HouseTrip as an example. We're a holiday rental marketplace, and
information about whether the properties we list are available or not for
given dates is backed by a table that looks like this:

    ┌────────────────┐
    │ availabilities │
    ├────────────────┤
    │ id             │
    │ property_id    │
    │ start_date     │
    │ end_date       │
    └────────────────┘

<br/>

At the time of writing, this table has shy of 1M rows.

Searching for available properties takes the form of a faily elaborate
query, with multiple joins, on various tables including `availabilities`.
This is plenty fast and scales well horizontally: so far our searches, and
most other read-y queries, are almost always handled by one of our MySQL read
replicas.

The problem is this scales poorly when the tables also take a lot of *writes*.

>  People searching for properties end up booking them, thus changing their
>  availability.
>
>  *Corollary*:
>  For the core tables (`properties`, `availabilities`, `rates`), our peak
>  traffic is both a read and a write peak.

The consequence is read contention. At some point, there are so many writes
that the readers (search queries) end up waiting too long for read lock.

This can be resolved in a number of ways:

- **scale out**: adding read slaves helps a bit, but you get diminishing
  returns; if you're saturating on writes, no matter how thinly spread the
  reads, they will disrupt your table. Also note that read replicas take
  exactly as many writes as your master.
- **scale up**: bigger servers, better IO. This pushes the problem back, but
  it's a single-barrel shotgun. Amazon (or whoever your host is) only has so
  many higher servier tiers.
- **use technology X**: some "architects", faced with data performance problems,
  have a single answer: *It's NoSQL'o'Clock!*. It might well be, but rebuilding
  a core system on top of Mongo (Riak, Redis, Couch, whatever rocks your boat)
  is a huge investment.
- **go async**: if reading slightly out-of-date information is good enough (a
  typical situation for search engines), segregates your reads from your writes.
  That's what we've tried out.


## Data tiering

"Data tiering" is the mechanism we currently use to reduce database contention
for our search. It's inspired by the
[double buffering](http://en.wikipedia.org/wiki/Multiple_buffering) used
in video cards.

The idea is to have search queries not hit the main database tables and
compete with updates and other queries, but instead have copies of relevant
tables. Those tables will be refreshed every few minutes.
We use it for all tables that get heavy writes and reads.
Every one of these regular tables now also has two clones: The *front* table
and the *back* table.

- Most parts of the application will keep using the original table for reads
  and writes.
- Any read-intensive part of the application (e.g. searching) will use the
  *front* table.
- No part of the application will ever use the *back* table.
- Every few minutes, a task (*errand* in our jargon) will sync all recent
  changes from the regular to the inactive table. Then the *front* and the
  *back* table will be swapped.

Conceptually:

                    ┌──────────────────────┐
            read <- │ availabilities_front │
                    └──────────────────────┘
                    ┌──────────────────────┐           
                    │ availabilities_back  │ <┐ update 
                    └──────────────────────┘  │         
                    ┌──────────────────────┐  │
    read/︎write  <-> │ availabilities       │ ─┘
                    └──────────────────────┘

### Syncing data

To detect changes we use MySQL timestamps (`row_touched_at`) that get
updated automatically by the database, regardless of whether you've done a
normal save, or some mass update. We don't use them for anything else in
our code as Rail's timezone handling does not work properly.

The column spec looks like:

    `row_touched_at` timestamp NOT NULL
        DEFAULT CURRENT_TIMESTAMP
        ON UPDATE CURRENT_TIMESTAMP

<br/>

This allows us to easily do partial updates of the back table instead of
copying all the data in bulk from the original table.


### Swapping tables

While we could atomically rename the front and back tables to implement
swapping (although it's unclear whether `RENAME TABLE` is atomic when
swapping), there's a simpler solution: pointers.

We use a place we can atomically write to (currently, another SQL table) to
store what table we mean when we say "front" or "back". The real tables are
named `availabilities_secondary_[01]`.


### Dealing with migrations

Our sync engine detects schema changes, by comparing the output of `SHOW
CREATE TABLE` (minus the `AUTO_INCREMENT` part, if any).

If you migrate one of the involved tables, the next sync will migrate those
as well, automatically.

If your migration doesn't touch the schema, but modifies the data, the
`row_touched_at` field will be updated—so changes, again, will be propagated
in the next sync.


## Conclusion

When we introduced data tiering, search query time at peak traffic dropped
by 30%.

The whole project took us less than 2 man-weeks to implement, test, and
deliver. It bought us time, and in that sense was a sensible solution to
scrape more performance out of our mostly-relational storage instead of
going through the massive investment of a foray into SOA and/or NoSQL lands.


#### Credits

Parts of this article are directly taken from the internal documentation
@kratob has written for us.


