---
layout: post
title: The case of Haml v. Erb
published: false
tags: ruby web performance
summary: |
  Is using Haml over plain old Erb just trendy?
  I think it is while hoping it lasts: I strongly believe Haml is superior in every respect to embedded Ruby---or almost any kind of "embedding" templating engine.
---


If you already know about Haml and ERb, jump straight to the [comparison](#comparison).

### ERb

Embedded Ruby, or ERb for short, is a templating engine with a syntax that'll be familiar to anyone coming form another framework ([PHP], I'm looking at you). That is, it's plain HTML (or whatever the target language is) with little bits of Ruby code, inside special tags, that get interpreted and replaced when the template is processed

    <% my_var = 'hello, world' -%>
    <p>
      <span><%= my_var %></span>
    </p>

becomes

    <p>
      <span>hello, world</span>
    </p>

Here's a [deeper intro](http://rrn.dk/rubys-erb-templating-system).


### Haml

[Haml] on the other hand, is not a templating language or engine (despite it's website saying so itself). It's a very compact Ruby-based [DSL] that generates HTML.

Being very closely related to [Sass] and [CoffeeScript], it shares a similar syntax (with significant whitespace).

The example above would look like:

    - my_var = 'hello, world'
    %p
      %span= my_var

and "compile" to the same snippet of HTML.


### Comparison

ERb has a very slight performance advantage ([1], [2]) over Haml (if using [Erubis], the Rails 3 default), but it'll only be visible on medium-to-high traffic sites (say, starting at 500 rpm). 

I think it depends widely on the *type* of project you're working on. 

Erb will be easier to tackle by inexperienced/cheap devs, mostly because it feels similar to what you'll see in PHP or other platforms, hence Hassan's comment above I suppose. 
(as a side note, significant whitespace is rarely an issue in my experience---only very junior devs still use tabs) 

Haml on the other hand has the advantage of compactness---it's leaner if you will, without being obsure. It's more top-down-readable. It feels like code, and not like a hackity-hack templating engine. It's quicker to write. 

Importantly, it also makes you DOM transparently visible in your code. 

In my opinion: if quality and low technical debt are important to you (i.e. if you're working on your company's product and not on consultancy work), Haml is the way to go. 
If your team is inexperienced (or outsourced), keep using Erb.



[Sass]: http://sass-lang.com/
[CoffeeScript]: http://coffeescript.org/
[DSL]: http://en.wikipedia.org/wiki/Domain-specific_language
[Haml]: http://haml.info/
[PHP]: http://www.php.net/
[deeper intro]: http://rrn.dk/rubys-erb-templating-system
[1]: http://blog.zenspider.com/blog/2009/02/tagz-vs-markaby-builder-haml-erubis.html
[2]: http://nex-3.com/posts/87-haml-benchmark-numbers-for-2-2
[Erubis]: http://www.kuwata-lab.com/erubis/

