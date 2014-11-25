---
layout: post
published: true
title: "Hiring remote workers: an engineering manager's perspective"
summary: |
  A lot has been written on remote work in the software industry, most notably
  Jason Fried's [Remote](http://37signals.com/remote/).
  Many of us were left agape by recent backlash on telecommuting by two
  megacompanies,
  [Yahoo](http://www.forbes.com/sites/jennagoudreau/2013/02/25/back-to-the-stone-age-new-yahoo-ceo-marissa-mayer-bans-working-from-home/)
  then
  [Reddit](http://venturebeat.com/2014/10/01/after-raising-50m-reddit-forces-remote-workers-to-relocate-to-sf-or-get-fired/),
  which added to the negative backdrop of
  [Google's](http://www.technologyreview.com/news/531056/google-execs-have-ideas-on-how-to-run-your-business/)
  reactionary attitude.
  <br/>
  I thought I'd share my experience as a tech lead to help spread the word: in
  spite of the fossils of 20th century management, the knowledge industry _can_
  go remote, and benefit from it.
  
  Mine is a real-world story about successfully turning a 10-person on-site team
  into a 30-person distributed team.
  What follows are a handful of factual observations and tips from my time as
  HouseTrip's head geek.
  
---


#### Abstract

Even proponents of remote work seem to think that you should either have a
distributed team from the get go, or stick to a traditional on-site team. Our
experience shows that this is incorrect.

We have gathered and present evidence that a going for a distributed team:

- can make hiring senior talent easier;
- does not require more than 10-20% on-site time;
- results in lower overall personnel costs, asymptotically 25% lower in our case;
- does not detrimentally affect productivity;
- requires a self-conscious approach but no unsurmountable effort.

We also share a few tips on how we believe it can be made to work, including:

- getting early, team-wide buy-in;
- starting small, experiementing with policy and processes, measuring, and iterating;
- being anal about excellence of communication and media;
- leading and trusting as opposed to managing and monitoring..


##### Back story

I've been a VP in the engineering team at [HouseTrip](http://www.housetrip.com)
from 2012 to 2014. Under my watch, the team grew roughly from 10 to 30
engineers. We had a great time building a leading, sharing-economy fueled
transactional website for holiday rentals.

Back when I joined, the team was on-site in our London offices, with an extra
3-4 [contractors](makandra). We sustained a hiring rate of 1 engineer per month
for about a year and a half, which in itself was an interesting challenge—how we
built a hiring while dramatically reducing churn will likely be the topic of a
future post.

Halfway through my tenure, we faced a major resourcing challenge: we were hiring
a lot of brilliant people, mostly people form outside the UK, and mostly
with less than 5 years of experience. Now, I love them to bits, but we weren't
getting any seniors through the doors.

And by seniors, I don't mean people with 3 or 4 years of experience (which seems
the norm in some companies), but people who'd been building software for
a _decade_, could mentor other, and lead technology decisions.

The lack of senior engineers caused imbalance: the team was was less productive
than it could be, made more mistakes or hasty decisions, and was frustrated by
the lack of people to learn from and bandwidth to experiment.
This also took a toll on the few thinly-stretched seniors we had, namely
[Matt](XXX), [Nas](XXX) and myself.


##### Seniors, Y U NO join?

Hiring developers is terribly difficult in London, and apparently in other tech
hubs worldwide, because the local job market is saturated (many competing offers
per candidate). The competition also is global. Some candidates will relocate,
but recent history has show that experienced candidates will not relocate to
London, even for very high salaries (e.g. 80k£ pa).

Jason Fried summs this up nicely in [_Remote_](XXX):

> Great talent is everywhere, and not everyone wants to move to San Francisco.

Our analysis at that point was that, given the competition and the very high
valuation in the market, non-financial considerations prime in a candidate’s
decision to join HouseTrip (or even consider talking to us). This is reinforced
for experienced candidates.

The three main criteria are, in order,

1.	lifestyle, particularly quality accommodation and social services;
2.	technological challenge and/or learning opportunity;
3.	team ethics, processes, and team leadership.

Due to the nature and history of our business, we have been able to neutralize
the last two criteria (i.e. avoid attrition to them) but not extract a
competitive advantage from them (i.e. make them a hiring argument).  Our
hypothesis was that 

- we could gain a competitive advantage on the "quality of life" criterion by
  enabling both candidates and existing staff to work remotely, part-time or
  full-time for the company, and that
- remote working can maintain or improve productivity.


## Facts: going remote works

From the moment we came to the observations above, we decided to run a "remote
work experiment" for a minimum of 6 months (it's actually been a year now).

The hypothesis was that remote work could actually work well, and the
expected outcomes were solid guidelines and good practices that would make a
distributed team sustainable.

The 4 sections below outline some of what we've discovered, in our particular
setting.



### Hiring remote seniors is easier

Several recent candidates had declined offers for the sole reason they would not
relocate to London, and mentioned they would have joined, had we welcomed remote
workers.

Obviously enough, there's an age bias at work:
"senior engineers" are at least in their mid-30s. Typically, they're in a
relationship; their partner is likely to have a job too, and many have kids.

This means they're less mobile: amongst other reasons you can't just ask their
partner to quit their job, or to uproot their kids from school, friends, and
family.

So we set to figure out how to change our recruitment practices to get those
profiles in as remote workers.

Our *sourcing process* ended up not changing much. Internally our team was two
people, Sandrine (head of HR) who generally only intervenes later in the
process, and Salim (talent hunter) who hunts for profiles and handles most of
the process (posting ads, pitching candidates, organising interviews, etc).

We ended up keeping a mix of:

- recruiters (but they were less effective finding remotes)
- in-house sourcing (fancy term for Salim sifting through LinkedIn profiles)
- employee referrals
- inbound through advertising

For us, referrals and advertising already had a regional reach. For instance,
our most successful job advert was [Ruby Weekly](XXX).
We also kept feeding our [tech blog](XXX), which didn't bring candidates in
directly, but did leave a positive impression—thereby helping conversion.

Recruiters became less effective, presumably because they're used to a more
local search and segregate between onsite/permanent on one hand and
contract/remote on the other.

Our *interview process* didn't change much either.
Given many of the people we hired previously lived abroad and moved to London,
our process was already suitable for remote hires.

The bulk of it, and importantly the first stages, consisted in 5 interviews: HR
intro, team-intro-career-culture-fit, 2 technical interviews. We used to believe
the technical interviews had to be done on-site; but with good usage of tools
(more on that later) we found out through trial and error that it's perfectly
possible to assess technical smarts over the wire. Importantly, remote technical
interviews are a reflexion of how we'd work with a candidate, with a similar set
of communication media (chat, screensharing, video).

The final round of on-site interviews was kept as-is: 1 one-on-one culture fit
interview, 1 presentation, and the inevitable HR chat/closing interview. At that
point the conversion rate is high enough to afford the plane tickets to fly
people in, and the nature of the interviews made them less suited for remote.

While I'd have loved to test candidates presenting remotely, that's probably a
little harsh! But we did make sure our remote candidates had some experience
working from home, even if not in a team (e.g. contracting).

I'll let the numbers speak for themselves:

    XXX
    GRAPH
    remotes seniors 6mo before: 1 (Tadej)
      +6 mid-level
    after: 5 (emili, andy x2, kris, cassio)
      +2 mid-level (remote)

Don't worry, there's a few graphs with hard data later on.
The important for now is this: with similar effort and an unchanged recruitment
budget, **hiring remotes was clearly a success** for us.


### 10% time on-site is enough

I'm very paranoid about team culture. Others have written better than I would
[why culture should not be
fucked](https://medium.com/@bchesky/dont-fuck-up-the-culture-597cde9ee9d4). If
you don't believe people are the most valuable asset in the knowledge industry,
the Financial Times [says you're
wrong](http://www.ft.com/cms/s/0/5731c4e0-edcf-11e0-acc7-00144feab49a.html#axzz3JLOrvaUz),
and scientists have been
[written](http://www.amazon.com/Management-Challenges-Century-Peter-Drucker/dp/0887309992)
about it for decades.  Culture is also an asset, and here's my
management-orientated stab at what culture _is_:

> Team culture is the intangible asset that makes groups of workers more
> productive, and stay longer in the company, that they would individually or in
> other teams.

Hint to VCs: measure happiness in your prospective start-up investments. You're
welcome.

In an era where attracting workers is costly, and particularly in startups where
efficiency is crucial, culture must indeed be excellent.

Back when the whole team was on-site, we'd focus on hiring people with whom we
shared a work ethic (no "rock stars"; you're here to learn and have an enjoyable
time; you're judged on what you deliver) and values (empathetic and
down-to-earth). We'd make sure the were decently skilled at had the potential to
grow. And we'd count on the "intangible" part of the culture to rub off.

We thought, the rubbing off wouldn't happen as easily with people being on the
other end of Skype or Slack most of the time. So we'd need either a
major rethink of how culture spreads and is stimulated, which we had no clue how
to do, or get people in regularly so the rubbing off would happen.

Needless to say, we opted for the latter. After some discussion we settled on
this rythm:

- For their entire 1st month, remote hire would live in London. This eased the
  onboarding process a lot, got them immersed in the team culture, and they had
  a chance to put faces on names and socialize a bit. A far as I know, they all
  loved it.
- From there on, they'd come back from 3 consecutive days, Wednesday to Friday,
  every other month. Friday is important because we have the team huddle in the
  morning and beer'o'clock at 5pm. Although we missed that the first few
  iterations, we figured it was best if they'd all come back at the same time.

Over a couple years, that's roughly 10% of the time on-site. As a remote leader,
we figured I'd come back twice as often—I ended up being on site about 20% of
the time.

We had plans for a "remote week" where everyone would come in for a week then
everyone (including management) would have to be remote for a week, but we never
put it to the test.

Culture is not easily measured, unfortunately, so we do not have elements of
proof beyond the generally increased job satisfaction in the team.



### Remote workers are less expensive

...with a naggy sub-fact: compensation is contentious and complicated. But then, isn't it
always.

The brilliant folks at Buffer introduced [open
salaries](https://open.bufferapp.com/introducing-open-salaries-at-buffer-including-our-transparent-formula-and-all-individual-salaries/)
a while ago, cinluding for remote workers.  I think they're unfortunately
biased, as they only seem to hire in high-cost-of-living locales. Their math is
wrong: you get a extra flat amount per year if you're in a high-cost city,
period. They ignore subtelties like tax systems, social security, or the local
job market.

Their formula-based system has the merit of simplicity, but it's simply not
enough in such a diverse landscape as Europe, where the cost-of-living and
taxation can differ by a factor 5 between countries (thinking of it, this
probably explains the mess our economy is in).

We decided instead to reason purely on a cost-of-living basis: for a given
candidate, decide how much we'd pay them in London, then run the math.

The principles guiding the actual compensation were then:

- The aim is to maintain comparable living standards between remote and onsite
  workers of similar experience and seniority, based on lcoal cost-of-living
  data;
- The local job market for equivalent positions is taken into account, with and
  aim to make offers in the 75th percentile.

For instance, cost of living is 20% lower in Lyon (France), 50% lower in Sofia
(Bulgaria) than it is in London. Copenhagen is about the same cost but the tax
there is mental. Differences in local wages, unsurprisingly, match cost of
living differences quite precisely.

Our formula would make sure the effective take-home pay, after all taxes, social
security contributions, and health insurance costs allows for similar standards
of living---purposedly _not_ the same absolute amount.

It was gruesome work, bu we put together a spreadsheet and added cities to it as
candidates came it. A few excellent sources of information:

- [Numbeo](http://www.numbeo.com/cost-of-living/) has details on costs of living, city by city;
- KPMG's [TIES
  series](http://www.kpmg.com/global/en/issuesandinsights/articlespublications/taxation-international-executives/pages/default.aspx)
  (for instance for
  [France](http://www.kpmg.com/Global/en/IssuesAndInsights/ArticlesPublications/taxation-international-executives/france/Pages/default.aspx)
  has precise information about the taxation mechanics in each country in the EU
  and the OECD.
- [Glassdoor](http://www.glassdoor.co.uk/) and
  [Payscale](http://www.payscale.com) both have decent information on local
  wages.

Of course workers abroad can't technically be employees, so we'd make sur to
bump the compensation up a notch to account for perks they can't get---e.g. sick
days; typically adding 5% to the total.

Travel costs also need to be factored in: typically £3,000 for 6x 3-day visits
per year (airline fares or roughly the same from any large city in Europe to
London when bought in advance).

And conversely, fixed costs are lower for remote workers. Just counting office
space, which costs about £3,000 per year, per seat in London, cancels out the
travel costs.

On average, remote workers end up costing the company **20% less** than on-site
workers. Not a bad argument when making the case to your CFO, especially if you
point out it's lower than what most eastern european software sweatshops will
charge you.


### Contracts and compensation caveats

Practices, employment law, and commercial regulations don't really get in the
way but they weren't designed for remote work.

#### Contracts

On the contractual side, remember that remote workers cannot
(practically) have an employment contract without being resident. This means
they'll have to set up a company of their own and invoice you. Many countries
have a special, simplified regimen for the "self-employed" or "sole traders".
This can be complicated to set up on their end; the paperwork takes up to a
couple of months in France, but only a few days in Poland or Bulgaria.

The trick here is that you do _not_ want remote workers to be sort of
second-class employees; their contract ahs to reflect that. We chose to tiptoe
at the edges of employment law to make their contracts as close to employees as
possible.

In practice, this meant factoring sick days into their daily rate and making
sure we'd pay their invoices at the very beginning of each month. It also meant
the contracts were 3-months rolling (to mimic notice periods) and 2-week
rolloing for the first quarter (to mimic the probation period).

Unfortunately, it wasn't possible to pay them a fixed amount per month, only
days actually worked; otherwise the contract would be too problematic legally.


#### Compensation

Over time, we've encountered some remote candidates who want London rates whilst
living in a lower-cost country.  I don't mean them any harm, but can't think of
any other term but "greedy".  I didn't believe in hiring these people. Not only
is it ethically debatable to pay someone a disproportionally large amount of
money, but it would create a very unfair imbalance situation in a team. Perhaps
the market will prove me wrong.

Conversely some companies use remote workers primarily as a means to cut costs,
and end-up hiring only remotes from low-wage countries. There's a saying about
peanuts and monkeys, of course. But more importantly, I think they're making
the same mistake as companie hiring only on-site: cutting themselves from most
of the global talent pool, by limiting themselves to "low cost countries".

For those outside the currency zone (Sterling for us), we chose to _not_ have
them suffer the Forex effects; they'd invoice us in their own currency,
typically Euro. This means costs vary somewhat, but fortunately the GBP/EUR
stays fairly balanced.

If they're outside the EU, we'd also have to take VAT into account, and possibly
import tariffs. We never had to face the situation, so I can't say much about
that.



### Distributed teams are as productive

As I mentioned earlier, we wore our scientist hats throughout our "remote
experiment" at HouseTrip. After all, we're breaking new ground---nothing of note
seems to have been published on teams going from on-site to distributed.

Team productivity is difficult to estimate for knowledge workers, especially in
an agile environment where objectives are loosely defined both in quantity and
in quality.  However, it is possible to

-	Use proxy metrics to compare test teams (within the area of impact) to the
  rest of the product team; 
- Use proxy metrics to compare productivity in the overall team before and
  during the experiment;
-	Complete a qualitative assessment survey at the end of the experiment.

All three come with caveats and are very noisy measurements. Fortunately,
because we're number freaks, we'd been tracking several metrics all along.

I'll jump to the results as you're probably expecting graphs at this point,
starting with velocity.

<figure>
  <img alt="Velocity graph" src="/public/2014-11-remote/velocity.png"/>
</figure>

Velocity is the amount of story points delivered each week. It's an
approximation of effort delivered. We extract this data from Pivotal Tracker's
API. This measure is dependent on team maturity (how long has the team been
working together?), average experience (senior engineers deliver 3 to 5 times
the work once onboarded; senior product managers and experienced lead developers
act as a multiplier up to x2), and part of the project lifecycle. We have over
18 months of historical data on this metric.

Our execution processes when we started hiring remotes were already well-oiled,
and we were planning to keep adapting them anyway. In particular, our
estimation practices ("how many points for this chunk of spec'ed out work?")
haven't changed much over time. 2 points is supposed to cost a day of work for a
typical engineer, and ends up taking a bit more, so typically we'd churn through
6 points per week, per person on average.

For reference, this is the number of active engineers any given week (the number
of engineers who completed any work):

<figure>
  <img alt="Active engineers graph" src="/public/2014-11-remote/actives.png"/>
</figure>

We started introducing remote work (hires, plus letting on-site workers remote
fairly freely) in January 2014.

The graph above speaks for itself: **remote had no significant impact on
velocity**.  If anything, it stabilized! The bump and trough in summer and fall
'13 matched a lower number of people being on-boarded, then a large number of
hires in rapid succession, taking a temporary toll on team produtivity.  No such
thing in '14, in spite of a similar number of----senior---hires.

<figure>
  <img alt="Team activity graph" src="/public/2014-11-remote/contribution.png"/>
</figure>


Velocity isn't meant for long-term projections, so we complemented with a couple
of other metrics including a _contribution score_. Contribution is our
measurement of activity in a team—basically you get points for every pull
request you submit (that's
[Github](https://help.github.com/articles/using-pull-requests/) lingo for
"submitting code for review"), comments on pull-requests, merging them, and
deploying to production.

This metric is more reflective of individual developer participation in
engineering (i.e. less has less team bias), and is less sensitive to raw skill,
competency, or experience.

The graph above (the size of the team is averaged out) clearly shows **the team
interacts more**, on average, over the first 3 quarters of 2014 than during the
same period in 2013, this in spite of up to half the team being remote.

These results came as a pleasant surprise to us, and match our gut feeling while
running the experiment. <br/>
While "remote" inevitably introduces some friction (even if timezones are the
same), remote workers don't have a crazy commute nor the stress of the big city,
and it seems to rub off on the rest of the team.


### Non-physical presence is a non-issue

In many companies, and in start-ups in particular, the myth goes that "magic
only happens when we're in one room". I attribute this to the lasting impact of
our pre-Internet era heroes, the canonical example probably being Steve and Woz
assembling the Apple I in a garage.

Countless modern examples, from people assembling to fund [projects](XXX) on
Kickstarter to the people [toppling oppressive regimes](XXX tunisia internet
revolution) by leveraging social media. There are, of course, brilliant examples
in the world of startups:
[Sqwiggle](http://sqwiggle.com),
a tool proudly supporting distributed teams, lists a few successful [tech
companies](http://blog.sqwiggle.com/6-remote-teams-and-how-theyre-changing-the-face-of/)
that went remote from the get go.

We're in the unique situation where we can measure the impact of non-physical
presence on a software engineering process, so let's see what happens to a team
that _went_ remote.

    XXX PR latency

Another metric we harvest over time is pull request latency, i.e. the time between issuance and merge.
If you're interested in measuring this for your team, the code's part of
[git-heroes](https://github.com/mezis/git-heroes#git-heroes).
We find this to be indicative of good communication and cross-team cooperation:
pull requests are reviewed asynchronously, and conventionally merged by a different person
thatn the issuer.

The stability of PR latency over time is, in our opinion, indicative that
**remote does not affect cross-team communication** (particularly given that
velocity is unchanged).




### Working remotely is _hard_

We're not debating that working in a distributed team is _harder_ than with a
fully on-site team, be it for those working remotely or those on-site if any.
Our point is that the benefits significantly outweight the difficulties.

This said, we believe that understanding those difficulties is critical to make
remote work. Here's a short list of the issues we've encountered.


_Cabin fever_: the lack of a real watercooler---or in London, of the after-work
pint at the pub can mean workers don't have a chance to vent. Individuals
problems (anything from lack of recognition to personal problems) can go
unnoticed, and this can result in frustration from remote workers.
We found that this can mostly be averted by re-creating a watercooler atmosphere
(e.g. in a cheerful #random channel in Slack), and by more proactive,
self-couscious management (more below).

_Time zone differences_: we experimented with workers 9 hours ahead of us,
therefore with minimal overlap between normal working hours. The experience was
disruptive and stressful both for the remotes and the rest of their on-site
team. We haven't found a good way to circumvent this; our conclusion is that time zone differences of up to ±4 hours (half a day) should be the limit.

We briefly considered to ask engineers to adjust their working hours to GMT,
also known as "work all night and sleep during the day".  Some outsourcing
companies, e.g. [Toptal](XXX), advocate this. To us, it's obvious that putting
workers in this situation would make them less productive, stressed, unable to
balance a healthy non-work life, and generally unhappy---the exact oppostie of
what we're after.

_Behaviour inertia_: particularly when stress levels go up (e.g. around a
deadline), we found that on-site workers would fall back into old habits. They'd
forget remotes during stand-ups, or turn their back to the camera. This was
particularly negative for remotes. <br/>
Again, being proactive (e.g. running retrospectives) and apologetic whenever
this happened (either because we forgot or because Skype went full FUBAR that
day) seemed to compensate the issue.

_Inexperienced remoters_: we envisioned this to be a problem, as we do not know
how to train a person to be efficient whilst remote. We chose to avoid the issue
bu favouring candidates with remote experience, or agree on a trial. As remote
work picks up in the industry, this will have to be addressed.

_Remote management_: as part of our "remote experiment", I went progressively
remote myself. Over a quarter, I went from 100% on-site to 80% remote (on a 20
days remote / 4 days on-site basis). <br/>
After a brief period of cabin fever on my end and sense of abandonment from my
team, we found a suitable rythm and communication style. One-on-one discussions
became more frequent, meetings became more focused (agendas!) albeit less
frequent, and gathering on-site with the team became more celebratory.

Our conclusion is that **having a manager at least part-time remote** was
instrumental into changing our practices to make "remote" work for us.



### Tips: making remote work.

for turning your team in 

##### Read!

[Remote: Office not required](http://37signals.com/remote/)
by Jason Fried of Basecamp (née 37signal) fame

[Ralph
Dandrea](http://workabilityblog.com/articles/2014/making-remote-work-workable/),
CEO of ITX (a small IT firm), has employees on 3 continents and writes about
what makes "remote work workable".

[Zaharenia](http://blog.sugarenia.com/archives/life/how-to-work-remotely-and-live-to-tell-the-tale),
a UX designer at workablefrom Workable

[Zapier](https://zapier.com/blog/how-build-culture-remote-team/) writes about
how to build culture in a remote team.
Also check out their previous article on a remote-oriented [hiring
process](https://zapier.com/blog/how-to-hire-remote-team).



##### Get buy-in

everyone on board
  not just management
  the _team_ too.
      they were asking for seniors
      we took the risk that some would want to go remote themselves
      be very transparent

##### Start small


##### Communication tools are crucial

Magic trio for us: Skype + Slack + Screenhero

avoid physical artifacts

boss insists on a Kanban board?
put it on a screen.

pair programming: Vim+Tmux kinda works ... Screenhero is much less painful

solid Internet connection
inexperienced remotes could think their 5/1 cable will work
minimum for smooth experience: 20/2 DSL with ~50ms ping times and no
throttling/caps
(might be a show-stopper for most parts of the US, but achievable throughout
Europe; I live in a town of 3,500 souls and have a 50/10 VSDL2 line)


##### Trust your team

cf. remote book chapter

[10/11/2014 13:30:36] Meelan Radia: did you use any software to manage the time
etc
[10/11/2014 13:30:41] Meelan Radia: eg
[10/11/2014 13:30:41] Meelan Radia: http://www.timedoctor.com/
[10/11/2014 13:30:43] Meelan Radia: or
[10/11/2014 13:30:50] Meelan Radia: http://hubstaff.com/
[10/11/2014 14:42:14] Julien Letessier: we considered it — but we ultimately
decided that
- what matters are results, not time spent working, so it would be a bad message
- we wanted a relationship based on trust in the team.

monitoring people assumes, as a default, that they're untrostworthy slackers.


we had issues with attendance (not sure that's the right word?) only with 1
person, and it was resolved easily.

getting meetings to happen smoothly
paranoidly instagating a habit of including remotes in all discussions

if trusted, in our experience,
remote workers are just as honest as on-site workers.
why wouldn't they?

##### Remote meetings can be smooth

anecdote: presentation over 3G line

good equipement
£1,200 per room, no ongoing costs


###### Accountability

stand-ups
Google snippets (for all, not just remotes!)


###### Communicate less but better

prepared meetings
agendas
async processes

killer: pushing back meetings
  symptoms that remote meetings are still too painful and people are lazy (which
  as you know
  is a [virtue](http://c2.com/cgi/wiki?LazinessImpatienceHubris) in software)


##### Education and experimentation required


how often should remotes come?
what process needs to be changed?
specifically, are extra meetings necessary?

-> remote retrospectives

should we hire for different skills?

not really, we already tested for English + ability to communicate over Skype during a
"normal" interview process

what about people who used to be on-site? should we allow switchers?
