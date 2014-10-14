---
layout: post
published: false
title: Machine-learning a search ranking engine for e-commerce (part 1)
summary: |
  A large catalog of products can be daunting for users. Providing a very fine
  grained filtering of search results can be counter-productive: it leads them
  from information overload to lack of choice. 

  On e-commerce sites, this results in poor conversion---users leaving the site
  without checking out.

  The key is obviously to provide _relevance_ and _choice_, which is much more
  complicated than it sounds, as different users may look for different
  products.

  This describes how I explored an AI-based, neural networks solution to
  relevance ranking.

---

_Disclaimer:_ if you're taking this seriously, take scientific advice. I've been
a scientist in another life, but what follows is really an engineering,
get-it-done approach to the problem.

Let's start with some background on the website I'm building this for.

HouseTrip is a holiday rental site; our products are flats and houses that
guests can rent for a period of time, in many (mostly European) cities. Our
users (guests) come from many different countries (again, mostly European), and
can be business travelers, couples, groups of friends, or families.

Let's assume I'm planning a trip to Paris with my wife and kid for the fall
midterm holiday. When I land on the site, I'm asked to enter a destination,
dates, and the size of my party, all of which I diligently enter.

<figure>
  <img src="http://cl.ly/image/01311L0U2k0q/capture%202014-10-14%20at%2009.35.05.png"/>
</figure>

The search result page (SRP) shows me a nice map and a number of properties. It
also suggest I refine my search by prompting me to open a filtering panel:

<figure>
  <img src="http://cl.ly/image/2K1p3m011B0z/capture%202014-10-14%20at%2009.32.30.png"/>
</figure>

Wow. Now, this is powerful. But 29 filters? And a total of 1,170 available
properties? I'm not quite a millenial, but I am lazy nonetheless, and I feel
bored already.  I'd really like this thing to just offer me a home I'd like.

After all, in the modern Web, I'm tracked and profiled everywhere, so I'm
entitled to a customised, tailored experience, right? Right?


--------------------------------------------------------------------------------


Unfortunately it's not that simple.
The website does know a few things about me: the place I want to go to, when,
and the fact I'll be travelling with two other people. It might also know I'm
using it in English language, from a Swedish IP address (ok, corner case here,
I'm behind a VPN), and possibly that I've visited before.

But that's really it.

It does _not_ know that the other people are my wife and kid (therefore, I need
just 2 bedrooms, not 3); or that I really need my Wifi fix; or whether I'm price
sensitive.

How can the app make an educated guess about the properties _I_ would like with
so little information? One answer is, simply, because it knows about other
people who have booked, some of which may be similar to me in some way---and it
could leverage that knowledge to tailor results for my benefit (and, well, the
company's).


--------------------------------------------------------------------------------


The very first "ranking engine" at HouseTrip was very simple. We would show
products that had been bought more often than others higher in the list.

After all, the feedback from our users was that those products "work", so why
not? Well, two main issues arose:

- sellers (hosts) would game the system by listing multiple product (properties)
  at once, to boost their ranking;
- new sellers and new products wouldn't stand a fighting chance to ever sell;
- and of course, this in no way guaranteed that users would see results that
  mattered to them.

The next step up, which we introduced in early 2012, was to rank results
according to a heuristic: our measure (as experts of the domain) of what a
"good" product was, in general, for users.

The general idea is to combine quantitative information about a given property
in a wieghted linear formula, the output being the ranking score.

We determined a set of measurable attributes of a property, which we proved to
correlate to the likelihood of it getting booked. We name \\(p\\) the vector of
normalized attributes:

$$
p = [p_1, ... p_n]
$$

This includes, for instance, the number of photos the host provided; the length
of its description; or the average time its host took to confirm a booking.

We then assigned each a weight, and defined the score as the weighted average:

$$
S(p) = {\large\Sigma}_{k=1}^n w_k p_k \ \big/\  {\large\Sigma}_{k=1}^n w_k
$$

The weights were initially defined very informally, as a combination of what _we
thought_ was important, and how well a particular attribute correlated with the
odds of conversion.

Importantly, we'd remove from the formula any attribute that couldn't be
measured (for instance, the time-to-confirm for new hosts), which is equivalent
to assuming a newly listed product is "average" for those attributes. This
ensured fairness.

On introduction, this new ranking mechanism gave us a 10-15% boost in
conversion (measured through split testing). Implicitly, this means that users
were getting more relevant results on average.

In the following 18 months, we iterated on the secret recipe, adding and
removing attributes and fiddling with the weights to gain further
improvements---still in a very scientific manner, but it "worked".

The optimisation we performed can actually be considered a manual (and
error-prone) implementation of a [gradient
descent](https://en.wikipedia.org/wiki/Gradient_descent) in the space of
possible weights.

We initially thought we'd try to generalise this an implement an on-line [genetic
algorithm](https://en.wikipedia.org/wiki/Genetic_algorithm) to learn the weights
automatically and adapt to changes in user behaviour... which sounds exciting,
but has a fundamental issue:

We'd still not be taking _the specific user_ searching for a product into account.


--------------------------------------------------------------------------------

Let's take a step back and formulate the problem we're trying to solve.

We want to show users _relevant_ products _first_. "Relevant" in this context
means "likely to engage the user". In e-commerce lingo, engagement means the
user will spend their hard-earned cash on your product.

So this is really a sorting problem. This reduces to a _comparison_ problem: if
you can order 2 products, there's a number of well-known
[algorithms](https://en.wikipedia.org/wiki/Sorting_algorithm#Efficient_sorts)
that can sort a list of products.

So what we're looking for is a black box that looks like this:


$$
\phi(u,p_1,p_2) = \left\{
\begin{array}{l l}
1, \text{if } p_2 \text{is more relevant than  } p_1\\
-1, \text{otherwise}
\end{array}
\right.
$$

where \\(u\\) is a vector of normalised attributes of the user, and \\(p_k\\) 
of the compared properties.

Whatever the black box ends up being, it will have a number of challenges to
face:

- there is little information about the user. In our context, we only know about
  their chosen locale, the destination they searched for, the dates at which
  they want to travel, and the size of their party.
- some of the information we have is continuous (e.g. the price of the
  property); some is discontinuous or discrete (e.g. the party size, number of
  photos), or even non-numerical (the locale, trip dates).
- the data we can train the black box on will be confusing (4 people travelling
  could be two couples, a group of friends, or a family with two children, and
  have very different expectations).
- the data is noisy (because the behaviour of individual humans is not very
  predictable).
- there are known non-linear relationships between inputs (\\(u\\), \\(p_k\\))
  and the value of \\(\phi\\): for instance, we know for a fact that price
  sensitivity in some destination is inverted for some locales, or some periods
  in the year.

That's for the bad news. Now, the _good_ news is that we don't have to be very
successful in designing \\(\phi\\): we just need to do better than a random sort
order, and better than the linear score \\(S\\) does.

In other words, our target is to beat this function (which ignores \\(u\\)):

$$
\phi_0(u,p_1,p_2) =  \left\{
\begin{array}{l l}
1, \text{if } S(p_2) > S(p_1)\\
-1, \text{otherwise}
\end{array}
\right.
$$


--------------------------------------------------------------------------------


Coming up with a good candidate for \\(\phi\\) with a supervised machine
learning technique requires three things:

- a dataset of training points, i.e. example instances of \\(u,p_1,p_2\\) where
  the value of \\(\phi\\) is known;
- an optimization algorithm that generates a candidate based on "training" data;
- a metric to determine how "good" our candidate is.

Finding what to learn _on_, i.e. our dataset, is actually tricky.
In our case, we're lucky enough to have harvested raw user behavioural
information (using [KissMetrics](https://www.kissmetrics.com/)'s data dumps, and
imported into [KMDB](https://github.com/HouseTrip/km-db#kmdb)). This contains
one entry per user and per key page of our transaction funnel (per page, if you
will).

Which point in the funnel should we learn on? Checkouts (bookings) sounds like
an obvious place to find "positive" training events: if \\(u\\) has booked
\\(p\\), we'd want \\(\phi(u,q,p)\\) to be 1 for most values of \\(q\\). Also,
we wouldn't be able to select good examples for \\(q\\). In other words, which
are the properties the user chose _not_ to book? Sure, they probably viewed the
listing page for other properties, but we'd need to be reasonably sure they chose not to
book because of the property itself, not for some other reason (e.g. finding a
place with the competition).

Ultimately, we chose our focal point as the point of enquiry (this is where
users ask the host to confirm availability, which is a preliminary step towards
booking). Think of it as a shortlist: a user browses several properties and opts
to enquire on a handful.

Our dataset is therefore:

- for all users \\(u\\) having enquired on a given day,
- for all properties in \\(P=\\{p_1,\ldots p_n\\}\\) that were enquired on by
  \\(u\\) that day, or visited in the 6 hours before the last enquiry,
- the set of tuples \\([u,p_i,p_j,\phi]\\), where \\(p_i,p_j\\) covers all
  combinations of an enquired and non-enquired property in \\(P\\), and
  \\(\phi\\) is 1 if \\(p_j\\) was enquired but not \\(p_i\\), and -1 in the
  opposite case.

Wew, that's quite a mouthful. Let's make this a bit more visual. Out dataset is
going to be a long list of this kind of data:

| user info  |  left property info  |  right property info  | \\(\phi\\) |
|------------|----------------------|-----------------------|------------|
| 1.2  3.4   | 5.6 7.0 8.1 8.2      | 9.3 5.2 4.3 3.9       | -1         |
| 4.0  2.7   | 7.0 9.0 0.7 0.6      | 0.6 9.5 7.6 3.8       | 1          |
| 1.3 5.1    | 8.0 9.5 7.3 5.2      | 3.2 4.7 4.7 6.1       | -1         |
{:.table.table-condensed}

(not the real data, of course)

A number of tricks are involved, of course:

- attributes are normalized from 0 to 1, with an attempt to "spread" the
  possible values as much as possible. For data that's distributed in a bell
  curve, that typically meant scaling so that the 5th percentile is 0 and the
  95th is 1. As we'll see in part 2, transforming the data (often using a
  logarithmic scale instead of linear) is a form of [kernel
  trick](https://en.wikipedia.org/wiki/Kernel_trick) that helps machine learning
  algorithm by linearizing the input.
- category information (e.g. locale) is converted into numerical information. We
  currently serve in 6 languages, which means instead of a "locale" column in
  the dataset, we'll have 6 columns, and for each user exactly one will have the
  value 1, and the others 0.
- replacing missing inputs with the median value for other entries. This only
  works well when the distribution is reasonably well known, and the relative
  number of missing inputs is low (experimentally, over 10% seems to start
  hindering learning).

We import all this into Redis, using a custom library called _pythia_ (bonus
points if you get the clunky allusion). We may or may not open-source it, but in
all likelihood, we won't if it ends up working super well, sorry.

At this point we feel like we have a solid set of data: roughly 1,500,000 entries
per month, or just under 40 million entries points total. Let's run a little
sanity check: is this enough data to find a good model of \\(\phi\\)?

Let's get an order of magnitude of how big the space problem is. For instance,
each of the _locale_ dimensions has 2 possible values, so the resolution is 2.
We've observed it's very rare to have parties of more than 8 people, so let's
say the resolution of that dimension is 8. A property can appear to have low, average, or
many photos (compared to its number of bedrooms), so let's say the dimension is
3. The price wan be significantly below, a bit below, a bit above, or
   significantly above the local market, so let's call that 4.

| dimension    | resolution |
|--------------|------------|
| locale       | 2^6        |
| party size   | 7          |
| trip length  | 5          |
| ...          |            |
| photos (p1)  | 3          |
| price  (p1)  | 4          |
| ...          |            |
| photos (p2)  | 3          |
| price (p2)   | 4          |
{:.table.table-condensed.dc-table-small}

If you multiply the apparent resolutions of all dimensions for our problem, this
tells you the number of "cells" in the _n_-dimensional grid of the attribute
space: in our case, that's roughly \\(10^{14}\\).

This means we're looking at one data point every \\(10^{14} / 40\cdot 10^6 ≈
2.5\cdot 10^6 \\) cell, also known as "not a lot". Plus the data's not just
sparse, it's likely to not uniformly cover the problem space either.

Practically this necessarily doesn't mean we won't be able to model, but we
shouldn't expect miracles.

We should, however, start putting this to the test.


--------------------------------------------------------------------------------


To keep experimentation realistic, we'll use 1 month of data for training, and
the following 2 weeks for control.  This isn't exactly by the book (you'd
normally take one set, and randomly pick
training and control examples), but the point of all this is to have
_predictive_ power, i.e. use past observations to predict future behaviour.

This is the point where you'll probably want to have read one of these two
books, although I'll do my best to stay legible:

<table>
<tbody>
<tr><td>
  <img alt="Programming collective intelligence" class="img-responsive" src="http://cl.ly/image/2e3B3C353o0e/capture%202014-10-14%20at%2018.04.00.png"/>
</td><td>
  <img alt="Machine learning for hackers" class="img-responsive" src="http://cl.ly/image/0e3d1E0T3f23/capture%202014-10-14%20at%2018.03.07.png"/>
</td></tr>
</tbody>
</table>

If your background is web applications and e-commerce, the green one is probably
an easier start. If you're an engineer with a strong CS background, go for the
red one. Both are excellent, as (mostly) is the norm with O'Reilly.

I've done my best to be algorithm agnostic so far, but the title and summary
gave away the approach anyways, so no surprises here: we're going to use
artificial neural networks (ANNs) to fit a model to our data.

While it's not the most state-of-the-art method out there, it's still [pretty
popular](http://en.wikipedia.org/wiki/Learning_to_rank#List_of_methods), and
importantly has been around for a while, which means:

- even non-experts will have some familiarity with the concept, unless they
  drank their way through college;
- there are good libraries floating around; we'll be using
  [FANN](http://leenissen.dk/fann/wp/), which has good [Ruby
  bindings](https://github.com/tangledpath/ruby-fann).

This [deck of
slides](https://sites.google.com/a/iupr.com/dia-course/lectures/lecture08-classification-with-neural-networks)
from the University of Kaiserslautern is a pretty decent intro to ANNs. It's
conveniently free if you don't have the books. And also, it's from a place
that's pretty close to Ramstein Airfield, which I found funny because of the
[other Rammstein](https://en.wikipedia.org/wiki/Rammstein) (which is indeed
named after the place!).

Now that's out of the way and you're familiar with ANNs, we're specifically
going to adapt (or take inspiration from) Tizano Papini's
[SortNet](http://phd.dii.unisi.it/PosterDay/2009/Tiziano_Papini.pdf) approach to
learning-to-pairwise-rank with neural networks.

Remember the naive, linearly-weighted ranking method I mentioned a few pages
above? It can be re-imagined as a trivial ANN, with no hidden layers, and where
the output node has a linear activation function:

<figure>
  <img src="/public/2014-10-learning/nn-sqs.svg"/>
</figure>

For comparison, the net we want to train will look like the following, with a
number of inputs for the user and the pair of properties we want to compare:

<figure>
  <img src="/public/2014-10-learning/ann.svg"/>
</figure>

You've probably noted there are two outputs, but we only want one value (+1 or
-1). The reason we'll train this way is that experimentally, it seems ANNs used
for classification work better with one node per category.

We'll simply map between the two by training with:

$$
[o_1,o_2] = \left\{
\begin{array}{l l}
  [1,0] \text{ when } \phi < 0\\
  [0,1] \text{ otherwise}
\end{array}
\right.
$$

and conversely, when apply a trained network to a control example:

$$
\phi = \left\{
\begin{array}{l l}
  1 \text{ when } o_2 > o_1 \\
  -1 \text{ otherwise}
\end{array}
\right.
$$

In English, we expect our net to have a high \\(o_1\\) when the property
\\(p_1\\) should rank higher, and vice-versa.


Training the network consists in presenting training examples to the network where the
"truth" is known (i.e. the values of the outputs are known), and running an
optimization algorithm to determine the weights of the connection between
functions. Typical algorithms fall in the
[backpropagation](https://en.wikipedia.org/wiki/Backpropagation) category.

Very fortunately, we don't really need to go much deeper, as the FANN library
will do all the heavy lifting for us.






difficulty of choosing 
- number of hidden layers?
- number of nodes?
- activation functions (sigmoid, linear, gaussian?)


outputs are known
control -> run on another set (with known outputs), compare the outputs from
running the network with the known ones
optimize for accuracy (% of TP+TN)

initial proof-of-concept:
point-wise instead of pair-wise

out of the product pages a user has visited, can we predict which ones he'll
engage with?

cascade-trained network

layout with 2 output nodes

So far, I've managed to extract data in a normalised format and I've started
trials on 2 months of data (august = training set, september = test set /
control).  Items are generated from the set of users having enquired: each
enquiry is a "positive" item and each PPP viewed but not enquired on is a
"negative".

Both the training and test sets have 150k+ training items.  Each item is an
input vector of 19 elements (information on the user, property, and location),
and a 1-item output vector (enquired / not enquired).

Using a cascade-trained NN (19 inputs, 30 neurons) as a classification
predictor, I'm getting 56.4% accuracy on the training set and **55.7% accuracy
on the control set** — i.e. significantly better than noise.

Just pulled a breakdown (not for the same net):

TP: 31.9%  TN: 23.8%  FP: 26.2%  FN: 18.2%
Accuracy (TP + TN) = 55.7%

[response/separation graph in email]

In other words, given a user/property combination, it can correctly predict
whether the user will enquire 55.9% of the time.<br> While not fantastic it's a
pretty good start — especially considering this is misusing NNs for our purpose:
the point is not to predict conversions, but sort properties.


A handful of performance facts:

- importing 2 months of data from various databases in to Redis takes roughly 30
  minutes, and consumes 700MB per month of data.
- exporting datasets to train on / test on takes ~5 minutes
- training the 19-input NN using the cascade algorithm takes about 10min (note
  that this algorithm also learns how many nodes are needed, and what their
  response function should be; not just the vertex weights).
- the 30-node NN I mentioned above can make about 120k predictions per second on
  my machine.


--------------------------------------------------------------------------------


next steps

refine (tranform inputs as needed, remove inputs which
may degrade learning)
try to go beyond that 56% mark

Next step is to give this a go on datasets containing _[user, location
property1, property2]_ items to predict ordering (where an enquired property has
a "higher" rank than a non-enquired one).

This is an easier problem (classification), and there's more data (all pairs of
property for a given user), so I'm quite hopeful we'll get even better results.



