---
layout: post
published: true
title: Using machine learning to rank search results (part 2)
summary: |
  In the [previous episode](/2014/10/learning-to-rank-1/), we've presented  ANNs
  (artificial neural networks) that could be used to improve the relevance of
  search results in an e-commerce context.

  We didn't go beyond the proof of concept though, and ended with more
  questions than when we begun.

  How can we make ANNs fast enough to sort tens of thousands of products? What
  network structure should we pick? How long does it take to train a network?
  Are we using the right inputs?

  We'll try to address and illustrate all of these questions.

---

<!-- START doctoc generated TOC please keep comment here to allow auto update -->
<!-- DON'T EDIT THIS SECTION, INSTEAD RE-RUN doctoc TO UPDATE -->
Skip to
  [Pairwise to pointwise ANNs](#pairwise-to-pointwise-anns)
| [Validating pointwise ANNs](#validating-pointwise-anns)
| [Training duration](#training-duration)
| [Number of hidden layers](#number-of-hidden-layers)
| [Hidden neurons](#hidden-neurons)
| [Improving quality of inputs](#improving-quality-of-inputs)
| [Removing bad inputs](#removing-bad-inputs)
| [Specializing by user segment](#specializing-by-user-segment)
| [Experiment wrap-up](#experiment-wrap-up)
| [Looking in the closer future](#looking-in-the-closer-future)
| [Conclusions & next steps](#conclusions---next-steps)
<!-- END doctoc generated TOC please keep comment here to allow auto update -->


Let's start by repeating the _Disclaimer_ from [part
1](/2014/10/learning-to-rank-1/): in spite of having a diploma that hints
otherwise, I wouldn't consider myself an expert in any of this. Proceed with
caution (the graphs are still cute, though).

Importantly, as this is not science, we'll be making making many assumptions so we can move forward. I did check that all results presented are consistent where applied to other datasets, but everything shown is run on a single, 1 month training + 1 month control dataset unless otherwise stated.

The ANN we ended up with so far proved that we can present search results that
can more accurately predict user engagement than random order, our our
historical, heuristic ranking (55% versus 50% and 44% respectively).
It was also really too damn slow: training it would take hours, and using it
would take seconds in the worst case.

We need it to be between 1 and 2 orders of magnitude faster to be able to

- provide live searches (our hero example being Google, not Kayak); and
- experiment quickly to answer the numerous questions above, in order to
  ultimately
- improve accuracy up to our (arbitrary) 60% target.


##### Pairwise to pointwise ANNs


We have a "performance problem" because:

- our dataset is large: training time is proportional to the size of the
  dataset.
- each entry has many inputs (28 inputs): both training time and runtime are
  proportional to the _product_ of the number of inputs and the number of
  hidden neurons.
- sorting a list of properties using our ANN requires \\(O(n \log n)\\), and up
  to \\(O(n^2)\\) runs of the ANN.

We'll explore training time in more detail later; for now, we need a solution
to this quadratic performance degradation.

To refresh our memory, the problem we're solving here is to _rank_, which
reduces to determining a property comparator:

$$
p_1 \succ_u p_2
$$

in proper English, we're trying to answer this question:

> Given a user _u_ and two properties _p1_ and _p2_, which property
> is the user most likely to engage with?

We want our comparator should be being true when _u_ engages with _p1_ but not
with _p2_, having seen both of their pages.
We've chosen to model this comparison function:

$$
\phi(u,p_1,p_2) = \left\{
\begin{array}{l l}
1, \text{if } p_2 \succ_u p_1\\
-1, \text{otherwise}
\end{array}
\right.
$$

using what we call a "pairwise ANN": one that takes as inputs attributes of
the user and of both properties.



What we'd really like is to find a way just to make \\(O(n)\\) calls to a
predictor, thus getting faster results.

Let's take a leap of faith and imagine we build an "pointwise ANN" to model this
function:

$$
\phi^*(u,p) = \left\{
\begin{array}{l l}
1, \text{if } u \text{ enquires about } p\\
-1, \text{otherwise}
\end{array}
\right.
$$

In other words, we're trying to find a function \\(\phi^\*\\) that _predicts_
whether a properties will be enquired about, rather than _comparing the
likelihoods_ of a property being enquired over another.

We could define \\(\phi\\) in terms of \\(\phi^\*\\):

$$
\phi(u,p_1,p_2) = \left\{
\begin{array}{l l}
1, \text{if } \phi^*(u,p_2) > \phi^*(u,p_1)\\
-1, \text{otherwise}
\end{array}
\right.
$$

because the comparison problem can be reduced to the prediction problem.
We also wouldn't need too, because ranking a list of properties \\(p\\) would be
as simple as sorting them by \\(\phi^\*(u,p)\\).

Let's compare what would happen performance wise. Assuming we have
80,000 users, each having 5 positive and 5 negative events (5 properties
enquired about, 5 properties just visited).

- For the pairwise approach, we have \\( 80\cdot 10^3 \times C_5^2 = 1.6 \cdot
  10^6\\) training entries;
- For the pointwise approach, only \\( 80\cdot 10^3 \times (5+5) = 0.8 \cdot
  10^6\\) entries.
- Instead is 28 inputs, we're down to 18: this reduces training time by a
  further third (assuming there are as many hidden neurons; we'll probably
  need less) and runtime by a third as well, because there is a third less
  connections in the ANN.

Overall

- training the pointwise ANN will be at least 3x faster than the pairwise ANN,
- using it to rank a list costs \\(O(n)\\) calls to the ANN instead of \\(O(n
  \log n)\\), with a lower multiplier to boot.


While at this point we'd expect the pointwise approach to yield a lower
accuracy, it's a reasonable direction to explore.


##### Validating pointwise ANNs

Building and training a pointwise ANN is rather straightforward, given at this
point we have the machinery in place to build and train pairwise ANNs. Our
networks now look simpler:


<figure>
  <img alt="Pointwise ANN" src="/public/2014-10-learning/ann-pointwise.svg"/>
</figure>

The dataset is also simpler, it is now a list of \\([u,p,o]\\) vectors,
where \\(o = [0,1]\\) is \\(u\\) engaged with property \\(p\\), and \\([1,0]\\)
otherwise.

To validate whether a pointwise ANN can be used for ranking purposes, we measure

- Its [RMSE](https://en.wikipedia.org/wiki/Root-mean-square_deviation) (the
  metric use during training, which is the square root of the mean of squared
  differences between expected and measured outputs);
- Its accuracy as a predictor (percentage of times the network makes a correct
  prediction about whether a user will engage with a given property, i.e.
  accuracy of \\(\phi^\*\\)),
- Its accuracy as a comparator (accuracy of \\(\phi\\) as redefined based on
  \\(\phi^\*\\).

on a handful of wide set of network layouts, which we let converge for an
unnecessarily large number of training iterations (known as "epochs").

Several coffees later, the jury is back:

<figure>
  <img alt="Pointwise accuracy" src="/public/2014-10-learning/accuracy-pointwise.svg"/>
</figure>

This confirms that, used as a pointwise classifier ("will the user enquire about
this property?"), ANNs "work". To be specific:

- The ANNs perform better with more nodes and plateau out, as expected;
- Accuracy on the control set is slightly lower than on the training set,
  without getting significantly worse (which would be a symptom of
  [overfitting](https://en.wikipedia.org/wiki/Overfitting))
- RMSE is a good predictor of accuracy.

The last point is particularly important. The two metrics are quite different
one is an objective quantitative measurement, the other is a count that could
vary wildly depending on the threshold chosen to discriminate our _positive_ and
_negative_ classes. Fortunately, they end up aligning fairly neatly.

For _pairwise_ accuracy, the
picture is similar:

<figure>
  <img src="/public/2014-10-learning/accuracy-pairwise.svg"/>
</figure>

Accuracy increases as RMSE decreases, which suggests that training (which
minimizes the RMSE of the pointwise prediction) also optimises accuracy.

This is what we're after, and going forward, we'll make the assumption that a
low RMSE is a reasonable proxy for a high pairwise accuracy, therefore a "good"
ranking.



##### Training duration


In the previous section, we trained numerous networks for 10,000 epochs, which
took the better part of a day on our test machine (Core i7 2.5GHz).  This is
unreasonably long for the other experiments we want to run, so let's take a look
to how quickly networks typically converge.

Note that while we've explored the other training algorithms provided by
[FANN](http://leenissen.dk/fann) (namely "batch" and "quickprop"), we stuck with
the default [iRPROP](https://en.wikipedia.org/wiki/Rprop) algorithm which
consistenly yielded more stale results and better final RMSE.

Training a first network (1 hidden layer, 8 neurons), and reporting on RMSE at
each epoch gives us a first hint at how it progresses:

<figure>
  <img src="/public/2014-10-learning/rmse-layout-8.svg"/>
</figure>

RMSE lowers rapidly at first, then progresses much more slowly. There's a cutoff
around the 400th epoch, then diminishing returns, and eventually stabilisation
around the 2,000th epoch.

Training a few more networks, and timing for a fixed number of training epochs
gives us a sense of how speed degrades with network size:

<figure>
  <img src="/public/2014-10-learning/epochs-per-second.svg"/>
</figure>

By the looks of it, training speed degrades roughly linearly with number of
hidden nodes; as a rule of thumb we'll consider that doubling the number of
hidden neurons increases training time for 50%---for a given number of epochs.

Now, our aim is to be able to train many networks in reasonable time, without
worrying we didn't let them converge long enough.
For this next experiment we train networks with 8 to 24 hidden neurons in 1 layer,
and reported the time spent and RMSE at each epoch:

<figure>
  <img src="/public/2014-10-learning/rmse-epochs-multiple-layouts.svg"/>
</figure>

All networks exhibit the same "hockey stick" convergence behaviour. After 2,400
epochs, the two smaller ones seem to have converged, but the three larger ones
are still slowly improving.

Interestingly, the three larger one also have a "dip" (around 800, 1,200, and
2,200 epochs respectively) where convergence speed quickly improves before
slowing down again.

Looking at the same data in terms of CPU time spent on training, instead of
number of epochs elapsed, does not help much further:

<figure>
  <img src="/public/2014-10-learning/rmse-time-multiple-layouts.svg"/>
</figure>

The only conclusion so far is that independently of the network size, we observe
a "hockey stick" convergence pattern; hitting the first plateau takes roughly 1
minute for a network of size 8, and that increases by roughly 50% for each
doubling of the network size.

Differentiating those curves, and plotting the _speed_ of convergence (variation of
RMSE per unit of time), makes this result more readable:

<figure>
  <img src="/public/2014-10-learning/training-speed-multiple-layouts.png"/>
</figure>

Each point here is the training speed (in ∆RMSE/second) for a network and a
given epoch. The points cluster to low, negative values on the left, as RMSE
goes down quickly at first; the then cluster around zero while staying negative
on average, as RMSE keeps going down, albeit more slowly. Asymtotically, the
average speed is zero, although all networks will exhibit noise, and fluctuate
around their optimum.

The hockey stick does end around 60 seconds for size 8 and 90 seconds for size
16. The "dip" at size 16, around the 180 second mark, is clearly visible.

Unfortunately, the larger networks are still converging at the end of our time
period; we can't easily derive for how many epochs, or for how much time, we
should let training happen.

For the rest of this exploration, we'll assume a training time of 2,400 epochs
is "good enough" to compare results between networks, and we'll regularly
confirm convergence by looking at the RMSE-over-time graphs


##### Number of hidden layers

Now that we have a basic sense of how quickly iRPROP converges, we should start
exploring for the ideal network layout. The experiments for far were with a
single hidden layer; does adding more layers change the performance in any way?

<figure>
  <img src="/public/2014-10-learning/multi-layer-rmse.svg"/>
</figure>

In this graph the series are named after the layout of the network: `24,8,4`
stands for 3 hidden layers, with 24, 8 and 4 neurons respectively.

The instability of training as the complexity of the
network increases is surprising. This also seems to be independent of the training algorithm
(similar behaviour is observed with Quickprop and Batch).

Apart from that, it would seem that adding an extra layer can, at least in some
cases (see the `24,8` example above), lead to faster training.

Taking a look at the accuracy of these networks suggests we should move on:

<figure>
  <img src="/public/2014-10-learning/multi-layer-accuracy.svg"/>
</figure>

The simple, single hidden layer network outperforms the more complicated ones.

##### Hidden neurons

Given the above, we'll settle on a single hidden layer.

There doesn't seem to be an agreed on way to determine the number of hidden
neurons. Stack Overflow, being its useful self, provides a number of [rules of
thumbs](http://stackoverflow.com/a/10568938/161487) (see [this
answer](http://stats.stackexchange.com/a/1097) as well).
The scientific literature isn't much more helpful.

The gist seem that the emphasis should be put on experimenting, and that the
number of input nodes, added to the number of output nodes, is generally a good
place to start. For us, that's 21 nodes in the hidden layer.

Out of curiosity (and a will to yield the best possible results, of course),
we trial all hidden layer sizes from 1 to 40, training them for 2,400 epochs.

<figure>
  <img src="/public/2014-10-learning/accuracy-by-size.svg"/>
</figure>

The pairwise accuracy (our ultimate measure of performance) seems to overall
increase with the size of the hidden layer. Performance for small sizes (1 to 3
hidden nodes) is too small to be reported (between 50 and 55%).

Interestingly, it would seem that some network sizes fare much better then
other, even after sizes over 15 where performance plateaus on average.
Sizes 16, 29, and 34 stand out; we are unable to provide a rational explanation
for this.

Let's take a closer look at how the networks were trained to make sure these
"peaks" aren't an artifact caused by stopping at a given number of epochs.
We plot their RMSE over epochs like above; we'll choose a different
representation, though, as overlaying 40 curves would be quite unreadable:

<figure>
  <img src="/public/2014-10-learning/rmse-epochs-contour.png"/>
</figure>

In this contour plot, training begins at the top (2,400 epochs "left" to train) and
ends at the bottom. We can clearly see the low-node-count ANNs at the left with
poor RMSE in green; the graph gets lighter to the right as RMSE gets lower more
quickly.
This also confirms our three "magic" layer sizes at 16, 29, and 34 nodes, where
we can see white "troughs" at the bottom of the graph, indicating the lowest
values of RMSE across our sample of networks.

These sweet spots are highly dependent on the input. While the exact portion of
the dataset we use seems to lead to the same sweet spots, changing the number of
inputs (more on this below) seems to shift the position of the sweet spots
dramatically.

While we have no explanation for these "sweet spots", they give us another clue
on how to continue experimenting: once we're done fiddling with inputs, we
should run this again to confirm what the ideal network size actually is.

_Note:_ the graphs above in this section actually correspond to our final,
massaged inputs; specifically with 1 bad input removed, and 2 inputs rescaled to
a logarithmic scale.



##### Improving quality of inputs

While all of our inputs are properly normalized, as is well explained in
[comp.ai.neural-nets](http://www.faqs.org/faqs/ai-faq/neural-nets/part2/),
some of them nor poorly _distributed_ in the inputs range (\\([0,1]\\) for us.

We plot the distribution of each of the inputs of our data set; most or
reasonably uniform, but two stand out:

- _population_, the population of the city
  where property \\(p\\) is, is heavily biased towards larger values, as most of
  the properties in our inventory are in larger cities; and
- _lead time_, the number of days between user's activity and their desired trip
  date, which is heavily skewed towards small values (as with many online
  activities, people seem to favour the last-minute purchases).

We rescale both inputs using a log filter, resulting in both cases in a
quasi-uniform distribution; we then re-train our group of networks. Finally, we
compare the results of this experiment (_X7_ below) to the networks with the
original inputs:

<figure>
  <img src="/public/2014-10-learning/log-scales.svg"/>
</figure>

The peak accuracy on the control set is indeed improved by "cleaning up" inputs.


##### Removing bad inputs

Some of the inputs in our datasets aren't very reliable. For instance, the
_population_ data is based on the [Geonames](http://www.geonames.org/), which is
often quite inaccurate, and has a _lot_ of missing data. So far we've operated
under the assumption that the information was missing for smaller cities, hence
replaced it with zero as an approximation.

We also wonder whether the user information, and the original ranking
score, are valuable inputs (in the sense that they help make predictions).

We run another series of experiments, and compare with the "base" scenario X7.
Here's an excerpt of the results:

<figure>
  <img src="/public/2014-10-learning/without-fields.svg"/>
</figure>

It turns out that all these fields are indeed useful. Particularly, using the
original ranking score as an input has a large impact; we believe this to be
because it incorporates information that we did not use as inputs so far, namely
some information about host behaviour, which we know _via_ other means, to
correlate to purchasing behaviour.


##### Specializing by user segment

Taking a step back, training ANNs for ranking purposes is all about specialising
search results for a particular user, in a situation when it is unrealistic to
segment users in groups of consistent behaviour. If that were the case, we could
use other tools like [decision
trees](https://en.wikipedia.org/wiki/Decision_tree) to rank properties, and life
would be boring.

This said, there is one dimension along which we can segment users pretty
efficiently: their locale. Here's an apparently reasonable hypothesis: if we
train one network _per locale_ (in other words, splitting our training sets by
locale), it could be easier to capture behaviour patterns. In other words,
people speaking the same language might exhibit consistency.

<figure>
  <img src="/public/2014-10-learning/fr-only.svg"/>
</figure>

As it turns out, not really. The graph above shows that when restricting
training to French speakers (about 25% of the overall data), accuracy _worsens_.
In other words, knowing about the behaviour from other locales helps predict the
behaviour of the French speakers.

As a Frenchman, I wonder whether to feel like offended by this neural net
telling me I'm not a beautiful snowflake.


##### Experiment wrap-up

Overall, we ran a few tens of experiments revolving around adding, removing, or
transforming inputs. The graph below shows the performance of the main ones:

<figure>
  <img src="/public/2014-10-learning/accuracy-x-experiment.svg"/>
</figure>

Our conclusion at this point is that more data seems to imply better training
results, and that [networks can't be trained on raw
data](http://www.stuartreid.co.za/misconceptions-about-neural-networks/#prep).
We had already filtered outliers (users making too many or too few enquired)
and normalized inputs; but transforming inputs so their values are well spread
gives us an extra gain.

Specializing the ANNs per segment doesn't seem to help either.


##### Looking in the closer future

Patterns of user behaviour evolve over time. Even more importantly, in an
e-commerce application like [ours](http://www.housetrip.com/), the segments and
volume of users change over time, due to both seasonality effect and marketing
tactics (for instance: changes in SEM targeting, TV advertising campaigns, etc.).

This could imply that what we've learned on a given month doesn't necessarily
apply in the far future. So far, we've trained on month \\(m\\) and controlled
on month \\(m+1\\). Let's take a look at how the predictive power of our ANNs
evolve over time.

<figure>
  <img src="/public/2014-10-learning/pairwise-weekwise.svg"/>
</figure>

For the first week of data in the control set (just after the training month),
accuracy is at its highest, and we actually manage to breach the 60% mark
occasionally.
It then degrades afterwards, losing roughly 0.5% per week.


##### Conclusions & next steps

Exploring the problem space if properly designing an neural network is
frustratingly slow, exploratory, and provides little scientific certainty.
Experiments tend to be reproducible to an extent, but everything is hugely
noisy. As a consequence, all of this is very imprecise; don't take our learnings
for granted, and experiment on your own data.

This being said, in _our_ scenario, a few conclusions can be drawn:

1. A pointwise ANN can be used as the building block of a comparator for ranking
   purposes, and it provides a decent proxy for a pairwise, SortNet-style ANN.
2. Training an ANN to convergence takes about 15 minutes for a 250,000 entry, 19
   input dataset, with 24 hidden neurons, on a modern machine (as of writing).
   Training time increases roughly linearly with the size of the dataset, number
   of inputs, or hidden layer size.
3. Larger, or more complex network sizes have little bearing on pairwise
   accuracy but they do slow down training (linearly) and can induce
   instability. The cutoff seems to be around 15 hidden neurons (roughly around
   our input size).
4. Networks with similar layouts can perform quite differently, so training
   should be done on several networks (for instance, ±2 neurons).
5. Performance is usually improved by providing more inputs, but those inputs
   should be scaled to cover the input range as uniformly as possible
   (typically, applying a log-scale transform to some inputs).
6. Predictive power degrades over time. When using this in a production setting,
   manually updating a comparator by re-training would not be very efficient; we
   should instead re-learn as regularly as possible, on rolling datasets.

After this journey into ANN handling, we feel like we have a firmer grasp on how
they behave. We're still a long way from using them in a production setting.

The next points we may want to explore include

- applying what we learned to pairwise networks, and
- experiment with stochastic learning techniques (probably a [genetic
  algorithm](http://en.wikipedia.org/wiki/Genetic_algorithm)) to circumvent the extremely
  slow learning of pairwise networks.

Time permitting, we may publish a third part in this series!

Recommended further reading: [Misconceptions about neural
network](http://www.stuartreid.co.za/misconceptions-about-neural-networks/), and
excellent introductory article by Stuart Reid.


