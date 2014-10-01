---
layout: post
published: true
title: Neural net training fail
summary: |
  So here I ham, having collected test and control samples to train a neural
  network, an measure its predictive power.

  But something's fishy: it works well, from the get go.

---

My current pet project involves prototyping a learn-to-rank engine to provide
more relevant search results on [HouseTrip](http://www.housetrip.com). I use
behaviour data from our users: simply put, positive events are users who enquire
on homes, negative events are those who stop at the listing page.  The point
being to predict, for a given set of search results, which the current user is
most likely to continue with. Or in other words, **provide relevant search
results to users**.

The first test net I tried has my 19 normalised inputs, 9 hidden nodes in 1
layer, and 2 outputs ("positive" and "negative").

Upon running my very first series of training using
[FANN](http://leenissen.dk/fann), I get this result:

- 90% correct predictions;
- 9% false negatives;
- 1% false positives.

How in hell can it work so well?

I then continue with different training set sizes, different network layouts,
with similar results.

And then eventally, I realise... that my data had _way more_ negative samples
than positives, because users view way more listing pages than
they continue and make an enquiry. So the damn thing was just predicting
"negative" all the time.... and it was generally "correct" given the data I fed
it.

Morality: when training something based on mean errors (RMSE in FANN, by
default)... your input needs to be as balanced / unbiased as possible.

I must be rusty at this.

Duh.

