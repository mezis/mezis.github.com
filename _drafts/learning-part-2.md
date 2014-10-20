---
layout: post
published: true
title: Using machine learning to rank search results (part 2)
summary: |
  In the [previous episode](/2014/10/learning-to-rank-1/),
  we've introduced you ANNs (artificial neural networks) could be used to
  improve the relevance of search results in an e-commerce context.

  We didn't go beyond the proof of concept though, and ended with more
  questions than when we begun.

  How can we make ANNs fast enough to sort tens of thousands of products? What
  network structure should we pick? How long does it take to train a network?
  Are we using the right inputs?

  We'll try to address and illustrate all of these questions.

---

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
  further third (assuming there are as many hidden neurons; way'll probably
  need less) and runtime by a third as well, because there is a thrid less
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

- Its [RMSE](https://en.wikipedia.org/wiki/Root-mean-square_deviation) (the metric use during training, which is the square root of the mean
  of squared differences between expected and measured outputs);
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
vary wildly depending on the threshold chosen to discriminate our _postive_ and
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
took the better part of a day on our test machine (Core i7 2.5GHz).
This is unreasoanbly long for the other experiments we want to run, so let's
take a look to how quickly networks typically converge.

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
a "hockey stick" convergence pattern; hitting the first plateau takes roughtly 1
minute for a network of size 8, and that increases by roughly 50% for each
doubling of the network size.

Differentiating those curves, and plotting the _speed_ of convergence (variation of
RMSE per unit of time), makes the result more readable:

<figure>
  <img src="/public/2014-10-learning/training-speed-multiple-layouts.svg"/>
</figure>

XXX explain!

The hockey stick does end around 60s for size 8 and 90s for size 16. The "dip"
at size 16, around the 180s mark, is clearly visible.

Unfortunately, the larger networks are still converging at the end of our time
period; we can't easily derive for how many epochs, or for how much time, we
should let training happen.

For the rest of this exploration, we'll assume a training time of 2,400 epochs
is "good enough" to compare results between networks, and we'll regularly
confirm convergence by looking at the RMSE-over-time graphs


##### Number of hidden layers

Now that we have a basic sens of how quickly iRPROP converges, we should start
exploring for the ideal network layout. The experiments for far were with a
single hidden layer; does adding more layers change the performance in any way?

<figure>
  <img src="/public/2014-10-learning/training-speed-multiple-layouts.svg"/>
</figure>

- second layer speeds up conversion
- leads to instability
- outcome isn't better


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

While we have no explanation for these "sweet spots", they give us another clue
on how to continue experimenting.





##### Improving quality of inputs

- log scale
- adding noise

##### Removing bad inputs

- check-in dates


##### Specializing by user segment


##### Looking in the closer future

- predictive power after 1w, 2w, ... 4w


##### Wrapping up


##### Next steps

applying what we learned to pairwise networks




