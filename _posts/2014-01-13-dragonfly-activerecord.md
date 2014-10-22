---
layout: post
title: Dragonfly backed by ActiveRecord
published: true
summary: |
  If your app's dynamic assets (user uploaded images for instance) weigh up to a
  few gigabytes, it can make sense to store them in the app's database instead of
  another service (e.g. Amazon's S3): your stack has one less dependency to care
  about, and backups get more complicated.

---

If you're using the excellent
[dragonfly](https://github.com/markevans/dragonfly) to manage and serve such
assets, we've just released
[dragonfly-activerecord](https://github.com/mezis/dragonfly-activerecord) which
lets you store assets to your app's relational database.

It chunks and compresses files, is compatible with a variety of Rubies and
databases, and is a drop-in replacements for Dragonfly's default stores.  It
also plays nicely with [Rack::Cache](http://rtomayko.github.io/rack-cache/)
and/or a CDN for better performance.

*This was reposted from [HouseTrip's developer blog](http://dev.housetrip.com).*
