---
layout: post
title: One-liner: fitting output to your terminal
published: true
tags: shell
---

Ever bugged when tailing logs or reading through the output of any command
and some lines are really too long?

Stick this function in your `~/.profile` or equivalent:

    fit () { 
      cut -c1-$COLUMNS
    }

Now you have a nicer way to tail logs:

    tail -F log/development.log | fit

Voila!
