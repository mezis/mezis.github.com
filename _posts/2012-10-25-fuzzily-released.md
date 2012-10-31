---
layout: post
title: Fuzzily, a Ruby gem for blazing-fast fuzzy text search
published: true
tags: ruby database performance
summary: |
  I just released [fuzzily](http://github.com/mezis/fuzzily), a small piece of software that gives you a way to very quickly perform fuzzy searches against tables in exchange for a little data and write overhead.
---

It's a [trigram](http://en.wikipedia.org/wiki/N-gram)-based, database-backed [fuzzy](http://en.wikipedia.org/wiki/Approximate_string_matching) string search/match engine for Rails.

Loosely inspired from this [old blog post](http://unirec.blogspot.co.uk/2007/12/live-fuzzy-search-using-n-grams-in.html).

Anecdotical benchmark: against our whole [Geonames](http://www.geonames.org/)-derived table of locations (3.2M records, about 1GB of data), on my development machine (a 2011 MacBook Pro)

- searching for the top 10 matching records takes **6ms** ±1
- preparing the index for all records takes about 10min
- the DB query overhead when changing a record is at 3ms ±2
- the memory overhead (footprint of the trigrams table index) is about 300MB

This looks like it scales very well, since the total number of possible trigrams is low (about 19k).

Pretty fast if you ask me!