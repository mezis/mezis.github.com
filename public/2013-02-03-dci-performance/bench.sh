#!/bin/bash

RUBY_VERSIONS="
  1.8.6-p420
  1.8.7-p371
  ree-1.8.7-2011.03
  1.9.2-p290
  1.9.2-p320
  1.9.3-p327
  1.9.3-p374
  jruby-1.6.8
  jruby-1.7.0
  rbx-2.0.0-rc1
"

for ruby in $RUBY_VERSIONS ; do
  rbenv local $ruby
  ruby bench.rb $ruby
done
