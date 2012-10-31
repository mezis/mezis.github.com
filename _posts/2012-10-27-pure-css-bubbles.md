---
layout: post
title: Pure CSS speech bubbles - configurable, with shadows
published: true
tags: sass css design
summary: |
  Without any trickyness or workaround involved, it is possible to render speech bubbles with perfect shadows entirely with CSS, using no images whatsoever.

  Even better, it degrades gracefully in Internet Explorer 7 and 8!

  This is how it looks like in modern browsers (Chrome, Opera, and Firefox):

  ![Rendered in Chrome](/public/2012-10-27-pure-css-bubbles.png)

---

In IE8, you lose the shadows and the bubble tips become all robot-y (because IE doesn't support CSS3's `transform` property at all):

![Rendered in IE8](/public/2012-10-27-pure-css-bubbles-ie8.png)

Finally in IE7 you lose the tips altogether:

![Rendered in IE7](/public/2012-10-27-pure-css-bubbles-ie7.png)

If this graceful degradation is acceptable to you, i.e. whoever wrote your brief understands IE is already going the way of the dodo, [here's the SCSS](/public/2012-10-27-pure-css-bubbles.scss) I built.

It comes with **variables** o easily adjust it to your use case.

You can play with it in this [JSFiddle](http://jsfiddle.net/mezis/abKFz/15/).
Enjoy!