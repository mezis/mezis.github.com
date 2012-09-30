---
layout: post
title: Released guignol 0.3.0
published: true
tags: ruby aws sysops
---

Be the puppeteer. Order your EC2 instances to start, stop, die, or be created from the command line. Let Guignol deal with DNS mappings and attaching EBS volumes.

Grab the brand-new Guignol with `gem install guignol`, or [check out the code](https://github.com/HouseTrip/guignol).

What's new:

- The tool's now [Thor](http://whatisthor.com/)-backed, which will make extension much easier.
- The config file format's been revamped (although backwards compatibility has been preserved).
- [Steve](https://github.com/screedon) has added a nifty `execute` command to run stuff on servers.

The test suite is still crappy, but hey, it's not like we've reached 1.0 with this :)

Happy puppeteering!