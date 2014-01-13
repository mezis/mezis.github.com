---
layout: post
title: Good software comes with a good README
published: true
summary: |
  Having a good README is crucial to see a software project get adopted and well used.

  Starting with a good README also helps you focus on your API or UI first.

  The TL,DR:

  - be concise and a bit sales-y
  - hand-hold your users into installation and initial usage, and around traps
  - make it a portal for further information

  Read on for a few hopefully useful hints.

---


Whether you're building a Ruby Gem, JavaScript library, new application, or
service, your
**fellow developers** will hopefully add features, integrate your software, deploy
it, or otherwise use it.

We're all aware that good design starts from the users' needs, not from data modeling, code
design, or architecture.

The very first piece of information those users will be exposed to is not
your database schema, a running app, and it's certainly not your test suite:

> Developers will start with your README

if only because it's your project's "landing page" on GitHub.

If your README is bad, depending on the situation they'll just move on and find
another tool, have trouble understanding what's going on, or misuse your
code. In a company setting, this is even more important as there might not
be another source of knowledge about the software (Stack Overflow,
blogs, etc.)

Here's a few thoughts on how to write a great README.


### Wear your salesman hat.

Why is this code important/interesting? The first paragraph of your README
pitches the project, it tells the user what the intent is, and in the case
of open-source software, why it may be more relevant to them than the
competition.

The first 40 characters should be crystal clear about the *what*, the next 100
about the *why*, which means the whole thing should fit in a tweet.

The next paragraph should elaborate and mention key features, and possibly
non-functional properties like performance (and in that case, point to
benchmarks).

Adding badges that show your code is tested and up to date, helps your
sales pitch.


### Where do I start?

Your pitch won't be enough, and users need to poke your software with a
stick.

Resist the narcissistic urge to rant about the merits of your code, and
make your first section about how to get the thing running. For a Rails
app, this might be something like:

> - make sure you have Ruby 2.0 and Bundler installed
> - copy .env.example to .env
> - add `FOO=BAR` to `.env`
> - run `bundle install`
> - run `rails server`, and head to `http://localhost:3000`

Any required configuration should be mentioned (ideally, if you have sane
default, this will be minimal). Have in mind that your users' environment
might be different—expect them to use a fairly vanilla setup, but you might
want to mention known incompatibilities/quirks, e.g. "if you're running RVM
instead of RBenv", etc.


#### Tests!

Letting users run tests when they start with your code builds trust.  For
an app, provide an example to manually "acceptance test" it, e.g.

> From `http://localhost:3000`, click on "sign in" and use "test/test" (works only locally).
> You should be greeted with a dummy catalogue of FizzBuzzs.


### Basic usage

While a README should generally not be a full-fledged documentation, getting
users to start tinkering with your library helps.

Provide a few code snippets for typical use cases. Here's a trivial example
taken from [will_paginate](https://github.com/mislav/will_paginate):

    ## perform a paginated query:
    @posts = Post.paginate(:page => params[:page])

    # or, use an explicit "per page" limit:
    Post.paginate(:page => params[:page], :per_page => 30)

    ## render page links in the view:
    <%= will_paginate @posts %>


### Address known WTFs

Libraries in particular will have quirks, best uses, and use cases where
they just don't cut it. Perhaps it doesn't work on large amounts of data, or
is too heavy to make sense on small amounts of data, or a known
incompatibility.

Don't leave users in the dark... this is the place to share it with them
or they'll find out they've wasted their time. They'll actually be grateful
if you mention that your shiny gem doesn't work with JRuby because it isn't
thread-safe!


### Pointers

Have more documentation? A wiki or a blog? Style guidelines? A process to
welcome contributions? This is where you put it.

Finally, if your code is open source, mentioning its licence in the README
will help its adoption in enterprise settings.

If you want inspiration on a good README,
[Sidekiq](https://github.com/mperham/sidekiq),
[Dragonfly](https://github.com/markevans/dragonfly), or
[Discourse](https://github.com/discourse/discourse) give a decent stab at a
clear README!



*This was reposted from [HouseTrip's developer blog](http://dev.housetrip.com).*
