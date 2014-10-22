---
layout: post
published: true
title: options
summary: |
  tbd
---

As an experienced software engineer who's mostly worked in start-ups (and
founded, then crashed one) I'm often asked by fellow engineers:

> Should I expect or ask for equity when joining start-up _Acme Corp_?

and the corrolary:

> Should I accept a "start-up salary" (i.e. lower than market)?


While I'm not a finance expert, I've seen people at the two extremes: either
being given way too many shares in a company, stifling its ability to raise
capital; or conned into working on the cheap in spite of being crucial to the
company's very existence.

Take what follows with a grain of salt; and if in doubt, talk to colleagues,
other engineers at conferences, or (especially if you live in a country with
poor worker protection, like the US or UK) seek legal advice.


##### What's equity anyways?

That's a more complicated question than I'm able to answer, and Wikipedia will
[do a better job](http://en.wikipedia.org/wiki/Equity) anyway; for the sake of
this article, equity is either a number of
[shares](http://en.wikipedia.org/wiki/Share_(finance)) or [share
options](http://en.wikipedia.org/wiki/Option_(finance)) (also known as stock
options).

Shares basically mean you "own" part of the company. If you have 10,000 of one
million outstanding shares in the company, you're entitled to 1% of the money if
the company gets sold.

But wait---it's not that simple. Shareholders typically sign a contract defining
some rules around money and decision making, and the contract may be
particularly complex and affect the value of your shares in various ways. To
give just three examples:

- The contract can specify that some types of shares don't open voting rights.
  This may effectively cut you off from deciding on whether to sell the company,
  IPO, hire a CEO, or what the executive team gets paid.
- There may be _prefered shares_; this is actually typical for the stock VC
  firms get in exchange for the money they invest. A typical scenario: VC
  invests 10M$ for 25% of the company. The company gets sold 80M$. They take
  10M$ (liquidation preference), and the rest gets shared amongst all
  shareholders---effectively, all non-VC shareholders were diluted. If the
  company gets sold for 10M$ though, they get 10M$ and everyone else gets zero.
- There can be a _ratchet clause_ whereby if the company doesn't meet certain
  performance targets, investors magically get more shares, thus diluting you.

Share _options_ on the other hand are a contract betwen you and the company,
that basically says: we reserve _N_ common shares for you. Once you've spent _T_
time with the company, you'll be allowed to buy these share at the "strike
price" _P_.

Typically, the strike price is set at (or occasionally lower than) the company's
current valuation; _T_ is known as the vesting period---the point of options is
to try and keep you for a longer period in the company (vesting is usually
staggered). Assuming the value of the company soars, this allows you to become a
shareholder "on the cheap".

A variety of online sources have mor information on how this works, including
[Socal
CTO](http://www.socalcto.com/2011/09/equity-for-early-employees-in-early.html)
and
[Techcrunch](http://techcrunch.com/2010/02/25/memo-to-ceos-founders-stop-being-such-cheap-bastards/).

Now, founders may be nice and smart people, but VCs are cold-blooded and _only_
after the money---Rightfully so: it's their job to maximise their fund's return
on investment.
[Cronyism](http://www.businessweek.com/articles/2013-07-24/did-ray-lane-cost-kleiner-perkins-a-slice-of-tesla-motors)
is not unknown with VCs, but usually, they're pragmatic.

For you this means that equity is of very little value if founders or management
are being opaque about:

- the term sheet (particularly on liquidation preference)
- the last valuation of the company
- the number of shares, including the size of option pool
- the option strike price.

Hiding any of this is ill-informed, as it would prevent you from properly
assessing what the equity is worth. Consider it a red flag: either the
founders/managers are not being straightforward, or they might not be competent.



##### When should I accept an under-average salary?

First off: you should never accept a salary significantly lower than what you
can live on, even if you have savings. Also be careful about reducing your
lifestyle significantly, as it can make you unhappy, may affect your family, and
reduce your productivity.

This said it can be reasonable to accept a reduced salary for a time, assuming
you know the risks and rewards well.

If you're at an under-market salary, you're facing similar risks as the founders
of the company. You should be able to reap comparable rewards (proportions
notwithstanding).

In a startup, even _at_ market salary for your seniority and position, you are
still taking a risk:  you could be working in a more secure environment, say in
one of the well-established companies in your field.

Remember that, depending who you ask, between
[50%](http://www.statisticbrain.com/startup-failure-by-industry/) and
[90%](http://blog.startupcompass.co/how-to-avoid-74-percent-of-startup-failures-benchmark-growth)
of all tech start-ups fail within the first 5 years; this risk should be matched
by a risk premium, even if it is somewhat offset by the [challenge and
experience](http://venturebeat.com/2014/09/12/hiring-startup-engineers-talk-about-challenge-not-pay/)
you can get in start-ups.

As an example, software engineering salaries in (funded) London start-ups
companies are typically 10 to 30% higher than in their larger, corporate
counterparts.

Back to the question:

- if you're not given any equity, you should not accept an under-market salary.
- if you're given at-market equity (see below), and at-market salary obviouly
  makes sense.
- if you're given a significant proportion of _shares_ (not options), consider
  consider an under-market salary.  This practically makes you a co-founder,
  probably one of the first 10 members of the team.
  



##### How much equity should I ask for?

know what you're worth
assuming a market salary
first engineer, no funding or seed funding: 5-10%
before series A: 1-2%
after series A: 0.5%
http://venturehacks.com/articles/option-pool-shuffle
http://dondodge.typepad.com/the_next_big_thing/2007/08/how-much-equity.html


##### How should I react if offered low equity?

know the people
track record of the founder (or the company if validated, i.e. it's been in business, and has
had customers for a couple years)
no or bad track record -> the equity is very probably worth nothing.
you can still work there, get a decent pay, and have fun though.
don't refuse the equity, but don't consider it more valuable than a lottery
ticket or a token gesture --- ie. it's not an argument to change your salary
expectations.



##### What are my shares/options worth?

run the math
https://news.ycombinator.com/item?id=4009862

> Make a guesstimate about the expected value of an exit, add some risk premium,
> and compare. e.g.
> If you assume $1B exit with prob. 3% (and no other outcomes), the expected value
> of the company is $30M. If you are offered 2% of the company over 4 years, that
> amounts to $600K or $150K/year at most (probably less, given tax considerations,
> exercise price, etc -- but let's assume the maximum).
> Now the risk premium: you can be fired at any point, you are 97% likely to only
> be left with salary, and there's the opportunity cost (if something good comes
> your way, you'll have to choose and essentially forgo the equity). Altogether in
> my book, that's a 75% risk premium. It's down to ~$40K/year for the equity
> value.
> So, in this case, I'd value e.g. $120K "no equity" with $80K "with equity".
> Now, if you think the company is going to top out at $100M at 3%, I'd value
> $120K "no equity" as $116K "with equity".
> When you look at it this way, it is clear that in the vast majority of cases,
> you should treat options/RSUs as lottery tickets or potential bonuses, but not
> much more.
> Unless you happened to be an early Microsoft, Google or Facebook employee
> (what's the probability of that?), you're almost surely better off with high
> salary.


on exit or sale, you can buy options and sell immediately
share option contract must allow for this (it's law in certain countries)

big red flag if the contract prevents you from exercising your options in case of a
sale or IPO

careful about vesting periods---never more than 4 years, and should start
vesting in a staggered fashion after 1 year

leaving early
"fair market value" = post valuation at last funding round

