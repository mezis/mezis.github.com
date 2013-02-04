# 
# Benchmark various dynamic object trait approaches in Ruby.
# 
# Not the prettiest script ever.
# Public domain.
# 
require 'delegate'
require 'benchmark'

COUNT = 10_000

# Test classes & modules

class MyClass
  def foo
    nil
  end

  def qux
    nil
  end
end

module MyMixin
  def bar
    nil
  end

  def qux
    nil
  end
end

class MyDelegator < SimpleDelegator
  def bar
    nil
  end

  def qux
    nil
  end
end

class WithInclude
  include MyMixin
end

# Benchmarked calls

def foo_normal_call
  MyClass.new.foo
end

def foo_with_extend
  MyClass.new.extend(MyMixin).foo
end

def foo_with_delegate
  MyDelegator.new(MyClass.new).foo
end

def bar_with_include
  WithInclude.new.bar
end

def bar_with_extend
  MyClass.new.extend(MyMixin).bar
end

def bar_with_delegate
  MyDelegator.new(MyClass.new).bar
end

def qux_with_include
  WithInclude.new.qux
end

def qux_with_extend
  MyClass.new.extend(MyMixin).qux
end

def qux_with_delegate
  MyDelegator.new(MyClass.new).qux
end

# Helpers

def disabled_gc
  return yield if defined?(JRUBY_VERSION)
  GC.enable
  GC.start
  GC.disable
  yield
end

def mem_usage
  `ps -p#{$$} -orss`.split[1].to_i
end

def run_benchmark
  disabled_gc do
    return Benchmark.measure { COUNT.times { yield } }
  end
end


def benchmark
  # warm up
  run_benchmark { yield }
  benchmark = run_benchmark { yield }

  # uncomment this to benchmark CPU usage
  # "%.3g" % [(COUNT / benchmark.real).round]
  # uncomment this to benchmark memry usage instead
  mem_usage
end

# Main

results = []
results.push ARGV[0]
results.push benchmark { foo_normal_call }
results.push benchmark { foo_with_extend }
results.push benchmark { foo_with_delegate }

results.push benchmark { bar_with_include }
results.push benchmark { bar_with_extend }
results.push benchmark { bar_with_delegate }

results.push benchmark { qux_with_include }
results.push benchmark { qux_with_extend }
results.push benchmark { qux_with_delegate }

puts results.join("\t")
