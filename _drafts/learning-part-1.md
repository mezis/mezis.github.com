---
layout: post
published: true
title: Using machine learning to rank search results (part 1)
summary: |
  A large catalog of products can be daunting for users. Providing a very fine
  grained filtering of search results can be counter-productive: it leads them
  from information overload to lack of choice. 

  On e-commerce sites, this results in poor conversion---users leaving the site
  without checking out.

  The key is obviously to provide _relevance_ and _choice_, which is much more
  complicated than it sounds, as different users may have very different tastes.

  This describes how I explored a machine learning, neural networks based
  solution to relevance ranking.

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

The search results page (SRP) shows me a nice map and a number of properties. It
also suggests I refine my search by prompting me to open a filtering panel:

<figure>
  <img src="http://cl.ly/image/2K1p3m011B0z/capture%202014-10-14%20at%2009.32.30.png"/>
</figure>

Wow. Now, this is powerful. But 29 filters? And a total of 1,170 available
properties? I'm not quite a millenial, but I am lazy nonetheless, and I feel
bored already.  I'd really like this thing to just offer me a home I'd like.

After all, in the modern Web, I'm tracked and profiled everywhere, so I'm
entitled to a customised, tailored experience, right? Right?


--------------------------------------------------------------------------------


Unfortunately... it's not that simple.
The website does know a few things about me: the place I want to go to, when,
and the fact I'll be travelling with two other people. It might also know I'm
using it in English language, from a Swedish IP address (Ok, corner case here,
I'm behind a VPN), and possibly that I've visited before.

But that's really it.

It does _not_ know that the other people are my wife and kid (therefore, I need
just 2 bedrooms, not 3); or that I really need my Wifi fix; or whether I'm price
sensitive.

How can the app make an educated guess about the properties _I_ would like with
so little information? Well, it does know about other people who have booked in
the past, some of which may be similar to me in some way---and it could leverage
that knowledge to tailor results for my benefit (and, well, the company's).



##### A simplistic ranking engine


The very first "ranking engine" at HouseTrip was very simple. We would show
products higher in the list if they've been booked more often---that is, sort by
descending number of past purchases.

After all, the feedback from our users was that those products "work", so why
not? Two main issues arose over time:

- sellers (hosts) would game the system by listing multiple product (properties)
  as a single entry, to boost their ranking;
- new sellers and new products wouldn't stand a fighting chance to ever sell;
- and of course, this in no way guaranteed that users would see results that
  mattered to them.

The next step up, which we introduced in early 2012, was to rank results
according to a heuristic: our measure (as experts of the domain) of what a
"good" product was, in general, for users.

The general idea is to combine quantitative information about a given property
in a weighted linear formula, the output being the ranking score.

We determined a set of quantitative, measurable attributes of a property, which
we proved to correlate to the likelihood of it getting booked. We name \\(p\\)
the vector of normalized attributes:

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
odds of purchase (as measured in historical data).

Importantly, we'd remove from the formula any attribute that could not be
measured (for instance, the time-to-confirm for new hosts), which is equivalent
to assuming a newly listed product is "average" for those attributes. This
ensured fairness.

On introduction, this new ranking mechanism gave us a 10-15% boost in
conversion (measured through split testing). Implicitly, this means that users
were getting more relevant results on average.

In the following 18 months, we iterated on the secret recipe, adding and
removing attributes and fiddling with the weights to gain further
improvements---still in a very unscientific manner, but it "worked".

The optimisation we performed can actually be considered a manual (and
error-prone) implementation of a [gradient
descent](https://en.wikipedia.org/wiki/Gradient_descent) in the space of
possible weights.

We initially thought we'd try to generalise this an implement an on-line [genetic
algorithm](https://en.wikipedia.org/wiki/Genetic_algorithm) to learn the weights
automatically and adapt to changes in user behaviour... which sounds exciting,
but has a fundamental issue:

We'd still not be taking _the specific user_ searching for a product into account.



##### Formulating the ranking problem


Let's take a step back and formulate the problem we're trying to solve.

We want to show users _relevant_ products _first_. "Relevant" in this context
means "likely to engage the user". In e-commerce lingo, engagement means the
user will spend their hard-earned cash on your product.

So this is really a sorting problem. This reduces to a _comparison_ problem: if
you can order 2 products, there's a number of well-known
[algorithms](https://en.wikipedia.org/wiki/Sorting_algorithm#Efficient_sorts)
that can sort an arbitrary-length list of products.

So what we're aiming for is a black box that looks like this:


$$
\phi(u,p_1,p_2) = \left\{
\begin{array}{l l}
1, \text{if } p_2 \succ_u p_1\\
-1, \text{otherwise}
\end{array}
\right.
$$

where \\(u\\) is a vector of normalised attributes of the user, and \\(p_k\\)
the attributes of the two compared properties. The operator \\(\succ_u\\),
informally means "more relevant than, for user \\(u\\)"; defining it clearly
will be part of the challenge.

Whatever the black box \\(\phi\\) ends up being, it will have a number of other,
data-related challenges to face:

- there is little known information about the user. In our context, we only know
  about their chosen locale, the destination they searched for, the dates at
  which they want to travel, and the size of their party.
- some of the information we have is continuous (e.g. the price of the
  property); some is discontinuous or discrete (e.g. the party size, number of
  photos), or even non-numerical (the locale, trip dates).
- the data has inconsistencies: 4 people travelling
  could be two couples, a group of friends, or a family with two children, and
  have very different expectations.
- the data is noisy: the behaviour of individual humans is not very
  predictable and has a hefty dose of randomness.
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




##### Obtaining data


Coming up with a good candidate for \\(\phi\\) with a supervised machine
learning technique requires three things:

- a "ground truth" dataset, i.e. a list of example instances of \\(u,p_1,p_2\\)
  where the value of \\(\phi\\) is known;
- an optimization algorithm that generates a candidate based on "training" data;
- a metric to determine how "good" our candidate is.

Finding what to learn _on_, i.e. our dataset, is actually tricky.
In our case, we're lucky enough to have harvested raw user behavioural
information (using [KissMetrics](https://www.kissmetrics.com/)'s anonymized data
dumps, and imported into [KMDB](https://github.com/HouseTrip/km-db#kmdb)). This
contains one entry per user and per key page of our transaction funnel (per
page, if you will).

Which point in the funnel should we learn on? Checkouts (bookings) sounds like
an obvious place to find "positive" training events: if \\(u\\) has booked
\\(p\\), we'd want \\(\phi(u,q,p)\\) to be 1 for most values of \\(q\\). But we
wouldn't be able to select good examples for \\(q\\), because those would be the
answer to "which are the properties the user chose _not_ to book?" Sure, they
probably viewed the listing page for other properties, but we'd need to be
reasonably sure they chose not to book because of the property itself, not for
some other reason (e.g. they had made their choice already, and were just window
shopping).

Ultimately, we chose our focal point as the point of enquiry (this is where
users ask the host to confirm availability, which is a preliminary step towards
booking). Think of it as a shortlist: a user browses several properties and opts
to enquire on a handful.

We can now define our relevance operator more clearly:

- \\(p_1 \succ_u p_2\\) if \\(u\\) enquired about \\(p_1\\) but not \\(p_2\\),
  and vice-versa;
- \\(p_1 =\_u p_2\\) if \\(u\\) enquired about both \\(p_1\\) and \\(p_2\\), or
  neither.

Our dataset is therefore:

- for all users \\(u\\) having enquired on a given day,
- for all properties in \\(P=\\{p_1,\ldots p_n\\}\\) that were enquired on by
  \\(u\\) that day, or visited in the 6 hours before the last enquiry,
- the set of tuples \\([u,p_i,p_j,\phi]\\), where \\(p_i,p_j\\) covers all
  combinations of an enquired and non-enquired property in \\(P\\), and
  \\(\phi\\) is 1 if \\(p_j\\) was enquired but not \\(p_i\\), and -1 in the
  opposite case.

Phew, that's quite a mouthful. Let's make this a bit more visual. Out dataset is
going to be a long list of this kind of data:

| user info  |  left property info  |  right property info  | \\(\phi\\) |
|------------|----------------------|-----------------------|------------|
| 0.12 0.34  | 0.56 0.70 0.81 0.82  | 0.93 0.52 0.43 0.39   | -1         |
| 0.40 0.27  | 0.70 0.90 0.07 0.06  | 0.06 0.95 0.76 0.38   | 1          |
| 0.13 0.51  | 0.80 0.95 0.73 0.52  | 0.32 0.47 0.47 0.61   | -1         |
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
say the resolution of that dimension is 8. A property can appear to have low,
average, or many photos (compared to its number of bedrooms), so let's say the
dimension is 3. The price wan be significantly below, a bit below, a bit above,
or significantly above the local market, so let's call that 4.

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

Practically this doesn't necessarily mean we won't be able to model, but we
shouldn't expect miracles.

We should, however, start putting this to the test.




##### Artificial neural networks


To keep experimentation realistic, we'll use 1 month of data for training, and
the following 2 weeks for control.  This isn't exactly by the book (you'd
normally take one set, and randomly pick training and control examples), but the
point of all this is to have _predictive_ power, i.e. use past observations to
predict future behaviour.

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
red one. Both are excellent, as is (mostly) the norm with O'Reilly.

I've done my best to be algorithm agnostic so far, but the title and summary
gave away the approach anyway, so no surprises here: we're going to use
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


Training the ANN consists in presenting training examples where the "truth" is
known (i.e. the values of the outputs are known), and running an optimization
algorithm to determine the weights of the connection between functions. Typical
algorithms fall in the
[backpropagation](https://en.wikipedia.org/wiki/Backpropagation) category.

Very fortunately, we don't really need to go much deeper, as the FANN library
will do all the heavy lifting for us.




##### Evaluating performance



The last piece of the puzzle is for us to measure how well (or poorly) our
trained networks perform.

Ours is a classification problem: for a given input \\([u,p_1,p_2]\\), we
classiffy "negative" entries where \\(p_1\succ\_u p_2\\), and "positive" those
where \\(p_1\prec\_u p_2 \\).  The traditional way to evaluate performance of a
classifier is to produce a [confusion
matrix](https://en.wikipedia.org/wiki/Confusion_matrix); and to get a single
figure for performance, reporting on _accuracy_ (the proportion of "correct"
predictions).

To get a sense of whether this would work at all, we train a network with our 28
inputs (10 for the user, 9+9 for the properties) using the [cascade training
algorithm](http://leenissen.dk/fann/html/files/fann_cascade-h.html) and a target
of 28 hidden neurons (completely random guessing that last figure).

Training, as mentioned above, is done on 1 month of user behaviour data. We
filter out outliers, e.g. users making way too many enquiries (more than 8),
users making too few enquiries (1 or 2), keeping only users who have viewed at
least as many non-enquired properties as they've enquired (ie. offer as many
positive as negative events), and so on. We then generate all possible pair of
properties for each user, and the desired output (\\([1,0]\\) or \\([0,1]\\)).
We also make sure there are exactly as many positive than negative samples
(otherwise things tend to [fail badly](/2014/10/neural-net-fail/)).

We generate a control set in the same fashion, on the 1 month of data following
our training set.

After training, and after running our confusion matrix script on the control
set, we obtain:

| true positive  | 31.9% |
| true negative  | 23.8% |
| false positive | 26.2% |
| false negative | 18.2% |
{:.table.table-condensed.dc-table-small}

which means our accuracy on the very first attempt is **55.7%**: our predictor
would be accurate slightly over half the time; which means that a property a
user would enquire about would be ranked above a property they wouldn't slightly over
half the time.

That doesn't sound too fantastic, but for a machine learning engine on human
data, it's actually quite good! Remember we only need to beat random sorting and
our original, simpler ranking.

Running the original, linear scoring-based ranking (\\(\phi_0\\)) on our control
data yields a surprising result: its accuracy is **44.5%**, which means it
performs _worse_ than random (we hadn't tweaked it in a while, and usage
patterns do evolve).

So even without further optimisation, our neural network would be a winner!

A handful of performance facts:

- importing 2 months of data from various databases in to Redis takes roughly 30
  minutes, and consumes 700MB per month of data.
- exporting datasets to train or control on takes ~5 minutes per month.
- training the 28-input ANN using the cascade algorithm takes about 2 hours (note
  that this algorithm also learns how many nodes are needed, and what their
  response function should be; not just the vertex weights).
- the 28-node ANN I mentioned above can make about 120,000 predictions per
  second on my machine, which means in the worst case (used as a comparator in a
  \\(O(n^2)\\) sorting algorithm) it could sort a set of 350 properties in a
  second. That's not going to cut it: a modern search engine should not take
  more than 500ms to provide results, and ranking is only part of the problem.




##### Beyond the proof-of-concept


At this point we've proven the approach could be viable, although significant
effort is still required.

Eventually this will need to be automated, relatively unsupervised, and _fast_.
When using ANNs, part of the difficulty (some would say magic) is to pick:

- the correct inputs (and transformations thereof)
- the number of hidden layers
- the number of nodes
- their activation functions (sigmoid, linear, gaussian?)
- the duration of training (number of "epochs")
- the training error function.

Our target is to achieve 60%+ accuracy, and be able to sort even large sets of
properties (2000+) in a few tens of millisenconds.

In part 2 (coming soon), we'll explore several of this points: expect lots of
graphs and data!

I hope this article will inspire some engineers to read on, and possibly apply
advanced techniques to building apps that work even better for consumers!



##### Frequently asked questions


- _Why do you call your second set a "control set" when the litterature
  typically says "testing set"?_ <br/>
  I wanted to emphasize that we're not training our ANN on a
  random subsample of a given data set and testing its performance on the rest;
  but rather, using two sets consecutive in time. Unlike other problems where
  ANNs are applied, ours is more a prediction problem than a modeling problem.
  Train on the past, control predictions on a known future.
- _How the machine perform when you use future data but you don't apply the
  same subset function?_ <br/>
  This is probably beyond what I wanted to cover in part 1; we could indeed try
  to learn on periods shorter or longer than a month. My hunch (and the results
  from part 2) is that, given the volume of data we have, a month is long enough
  to capture diverse user behaviour, and short enough to capture seasonal
  changes in said behaviour.<br/>
  I did test on other months in our source data with very similar results.
  




