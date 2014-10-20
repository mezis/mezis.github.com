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
  <img src="/public/2014-10-learning/ann-pointwise.svg"/>
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
  <img src="/public/2014-10-learning/accuracy-pointwise.svg"/>
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

For this experiment we trained networks with 8 to 24 hidden neurons in 1 layer,
and reported the time spent and RMSE at each epoch.

- convergence speed
- number of epochs
- show for 3 network sizes

##### Hidden neurons


- effect of number of nodes
- 1->40 nodes
- countour plot
- "sweet spots" with no explanation


##### Number of hidden layers



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




