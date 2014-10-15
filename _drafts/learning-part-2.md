---
layout: post
published: true
title: Using machine learning to rank search results (part 2)
summary: |

---


used a classifier of positive v negative events

problem is ultimately to _rank_, i.e. sort user, property pairs based on:

$$
[u,p1] > [u,p2]
$$

in proper English, we're trying to answer this question:

> Given a user _u_ and two properties _p1_ and _p2_, which property
> is the user most likely to engage with?

being true when _u_ engages with _p1_ but not with _p2_, having seen both of their
pages

$$
\phi(u,p_1,p_2) = \left\{
\begin{array}{l l}
1, \text{if } [u,p_2] > [u,p_1]\\
-1, \text{otherwise}
\end{array}
\right.
$$

"pairwise net"

pairwise v prediction
using signal to sort: slightly lower accuracy, massively faster training and use
O(n) v O(n log n)

learning is also much slower
80k users
5 pos, 5 neg each
C(2,5) = 20 pairs each
1.2M learning examples!

----------------


leap of faith (not doing science here anyways, but engineering), simulate with :

$$
\phi(u,p1,p2) := \phi^*(u,p1) > \phi^*(u,p2)
$$

in English:
assume than where a point-wise network gives a _higher_ response on _p1_ than
_p2_, the likelihood of _u_ engaging with _p1_ si higher than with _p2_.

inconsistency stems form the fact we'll train on something different -
particular outputs values.

still control on pairwise accuracy
find the \\(\phi^\*\\) that provides the best pairwise accuracy
i.e. explore the inputs

then go back to training on a pairwise network

-----------------

Another quick update:

I’ve automated & cleaned up a lot of the import, export, and train code.
I’m focusing on learning pairwise ordering now, following the approach in http://phd.dii.unisi.it/PosterDay/2009/Tiziano_Papini.pdf
(short version: if you learn to order pairs, you can order whole sets).

The nets also have more inputs: 10 for the user, 9 for each property in the pairs being evaluated.
I’m using a bit less data (15 days train, 15 days control) as the pairs of positive/negative events represent a huge set (2 weeks is about 1 million points),
in order to still have reasonable training time.

As anticipated accuracy is higher than with the preliminary “prediction” experiment:
testing a few naive network layouts, I’ve gone as high as 61% accuracy on the control set.
(Paul: that’s with 19.4% false positives and 19.6% false negatives)

In english:
Using this, for a given user, we would have a 61% chance to rank a property the user enquired on than one he didn’t enquire on.

It looks like the ideal number of neurons is lower than the input size, unsurprisingly close to 19 (each user input + 1 for each property input).

I’ll refine a bit, show you some graphs, and start building the actual “ranking” part.

-----


filtering by segment (locale)
no improvement in learning - but fewer nodes needed



