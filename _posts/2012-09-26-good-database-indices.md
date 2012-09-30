---
layout: post
title: "Tip: Good indices in relational databases"
published: true
tags: rails database performance
summary: |
  ActiveRecord, like any other ORM (Hibernate, Datamapper, et al.) adds lots of
  sugar for your persistence needs, but it's not magic.

  On of the things it won't do for you is make sure your queries run quickly.

  Here's a few tips to achieve what is often overlooked in Rubyland.

---

Whether you modify an existing named scope or add a new one, or when you write a new query, make sure you have the proper indices.

This particularly applies if you're going to run non-trivial queries of course (admin backends, analytics, etc).


### Compound indices

A chain of scopes results in (usually) one query. You should take into account all attributes (columns) that are used in `:conditions`, `:join`, `:group`, `:having`, and `:order`, as all those result in filtering and sorting–slow operations without indices.

Take the list of all those attributes: the table should have at least one compound index that includes all those attributes.
It can sometimes be enough to already have an index on a subset of your query's columns, but it is **not** enough to have 2 indices covering all your columns

If not, add a new index.


### Index order

Ordering keys in indices is important: in general, order columns in your index from lowest to highest cardinality, typically flags and enumerations first, then foreign keys, timestamps, and finally your table's primary key (`:id`).


### Using parts of indices

When looking for an index to use, MySQL only use leftmost parts of compound indices. For instance, if querying on columns `a`, `b`, and `c`, an index on `(a,b)` will be used, but not an index on `(b,c)`.


### Issues with sorting

When sorting, only leftmost part of indices are used. To optimize sorting you'll need an index that starts with your sorting criteria in the same order.

For instance, if sorting with `:order => "created_at DESC, id DESC` you need a compound index that looks like:

     add_index :things, [:created_at, :id]

Sort *direction* is important too. Don't mix `ASC` and `DESC` or no indices will be used.


### Using *EXPLAIN*

All the above is more guidelines than general rules.

To figure out whether your query's efficient or not, just run your query prefixed with EXPLAIN.
If it tells you it's using temporary tables or filesort... your query's probably not going to be very fast.


### Example query

    SELECT `orders`.*
         FROM `orders`
    INNER JOIN `payments`
        ON payments.order_id = order.id
    WHERE (order.status IN ('confirmed','pending')
    GROUP BY order.id
    ORDER BY order.created_at DESC, order.id DESC
    LIMIT 0, 100

Efficient indices:

    add_index :payments, [:order_id]
    add_index :orders, [:status, :created_at, :id]
