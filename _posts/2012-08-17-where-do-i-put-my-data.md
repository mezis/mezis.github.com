---
layout: post
title: Where do I put my data?
published: true
tags: ruby rails design good_pratice
summary: |
  Your typical web application doesn't just need data about your customers' accounts and your products' prices.

  Quite a part of the information you need is transient: last login timestamp,  number of times a product was sold, a user's unread message count, and so on.

  It doesn't really matter which language, ORM, or structured datastore you're using–be it Ruby on Rails, Django, or Symphony, backed by MySQL or MongoDB.
  Structured storage is complex to manage.

  Where should you store data? Here's a few tips.
---

I'll use the example of your off-the-shelf Rails app: persistence is achieved through ActiveRecord, and Memcache  is used for action caching for instance.

A commonly seen practice is to throw every bit of data you can think of at your models' backing store, just because it seems simple.
And to an extent, it is, because it's the default Rails' way
(lack of support for tying models and caching in Rails doesn't help.)



### Why not use ActiveRecord for everything?

Three main reasons.

*Speed*: ActiveRecord is slow (so are DataMapper, Mongoid). The faster select from your backing store is always going to be slower then querying Memcache.
Writing data to ActiveRecord is even worse–if the data goes to one of your core models (say, `User`) you're looking at a full order of magnitude slower than your cache.

*Uptime*: Changing the data you place in ActiveRecord requires migrations, and even if you're very careful, migrations will incur downtime.
I'm currently running a 2,000 requests per minute website where downtime is becoming unacceptable.

*Scalability*: Last but not least, the dirty secret of structured stores (SQL or otherwise): they scale very badly. For reads, you can get away with replication. For writes, sharding is sometimes an option–but in general you'll hit the wall running somewhere around a few 10s of thousand queries per minute.

Memcache, on the other hand, scales perfectly: performance will remain a constant O(1) as long as you keep adding memory and/or servers.


### Caching in practice

Let's assume you have a blog engine and want to add a counter of posts next to each user.

    class User < ActiveRecord::Base
      has_many :posts

      def post_count
        Rails.cache.fetch("#{self.class.name}|#{id}|#{__method__}") do
          posts.count
        end
      end
    end

In this trivial example, you could use counter caching of course. But why should you? The above is going to be much faster, and look ma! no schema change, no downtime.

Of course this would make even more sense if your cached method is fairly complex to compute.

Afraid of the slight hit with cache misses?
You could pre-populate your cache with a background job, have it recalculate as posts get added, and even just invalidate it when new posts get added. One way to do this (amongst many variants):

    class Post < ActiveRecord::Base
      belongs_to :user, :touch => true
    end

    class User < ActiveRecord::Base
      has_many :posts

      def post_count
        Rails.cache.fetch("#{self.class.name}|#{id}|#{updated_at.to_i}|#{__method__}") do
          posts.count
        end
      end
    end

Here we make the cache key dependent on the user's modification timestamp, and touch the user as posts get posted.


### The magic recipe

Here is my take on a recipe to decide wether I should persist data *X* to ActiveRecord–or store it somewhere else.

##### Can I recalculate data *X* from other piece of authoritative, ActiveRecord-backed data?

If not, simple answer: store it in ActiveRecord.

##### Do I need to **order** records against my data *X*?

*X* could be, for instance, the number of likes on a blog post, and you'd like to display posts by popularity.

If true, and your dataset is large (100+ records), store it in ActiveRecord. Otherwise send it to Memcache and just do the sorting in Ruby.

##### Do I need to **search** records with respect to my data *X*?

Same as above. Unless your dataset is large, use Memcache.


That's it–It's really that simple!


### Final thoughts

I recommend to be strict about this in your teams. If it doesn't need to be in ActiveRecord, just don't put it there.
Beware of *what if*'s: If you think that it'll have to be in AR in the future, it will be simple enough to move the data over.

