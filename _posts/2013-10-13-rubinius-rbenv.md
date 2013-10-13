---
layout: post
title: Rubinius 2.0.0 + Rbenv
published: true
tags: ruby
summary: |
  [Rubinius 2](http://rubini.us/) didn't work for me out of the box using
  [RBenv](https://github.com/sstephenson/rbenv): in particular it wouldn't
  find gem executables like `bundler`. Here's how to fix it.
---

Update Rbenv and `ruby-build`:

    $ (cd ~/.rbenv ; git pull)
    $ (cd ~/.rbenv/plugins/ruby-build ; git pull)

Install Rubinius:

    $ rbenv install rbx-2.0.0

Add RBenv hooks to detect Rubinius gems by creating two files:

    # in ~/.rbenv/rbenv.d/rehash/rbx-2.0.0.bash
    make_shims "~/.rbenv/versions/rbx-2.0.0/gems/bin/*"
 
    # in ~/.rbenv/rbenv.d/which/rbx-2.0.0.bash
    if [ ! -x "$RBENV_COMMAND_PATH" ] && [[ $RBENV_VERSION =~ rbx-2 ]]; then
      export RBENV_COMMAND_PATH="${RBENV_ROOT}/versions/${RBENV_VERSION}/gems/bin/${RBENV_COMMAND}"
    fi

Install bundler:

    $ gem install bundler

Go to your app and bundle!

    $ cd ~/myapp
    $ rbenv local rbx-2.0.0
    $ bundle install

Ta-da!