# elixir_map_pmap_apmap_example


Example of how to make a function, when called can either perform synchronously or
asynchronously. A  <b>map</b> function is used as the example.

The cool thing about this code is, as a user of the function (the caller) you don't know
which version it will use. In most other languages (like Javascript), this is an
exceptionally bad idea, but in Elixir this is actually a common way to solve problems.

`"Javascript with Promises"`, by Daniel Parker has this warning:
```
WARNING
Functions that invoke a callback synchronously in some cases and asynchronously in
others create forks in the execution path that make your code less predictable.
```

But we ignore this warning in Elixir :) , because there is only one execution path
for a delayed job - messages which your process will handle when it wants to.

For example, the Logger works like this in Elixir. If the backlog of things to log is
small, then it completes synchronously, otherwise it will decide to switch to
asynchronous mode, just like magic.


Here's what the code invoked looks like:
```
result = Parallel.map_or_pmap_or_apmap((0..10), fn(x) -> x * x end)
```

result will either be:

```
{:ok, result_arr} # result is available synchronously
{:delayed, pid}  # this is going to take a while, I'll send you a message when it is ready
```


Depending on the size of the Range passed to the map_or_pmap_or_apmap function, the
work can be accomplished in one of three ways:

1. For small arrays <= 100 elements in size, it just runs in process synchronously
1. For medium arrays <= 1000 elements in size, it runs parallel map (multiprocess), but synchronously to
the caller.
1. For anything bigger it runs parallel map, but does it asynchronously and sends a response when it
it done with the work.

Waiting for the delayed result is accomplished by waiting for a message from
the <b>pid</b>.

```
receive do
  { ^pid, result } -> IO.puts("Results have ready. Yay!:")
                      IO.inspect(result)
end
```

Improvements: Probably should have the result actually be {:ok, array} so that
the asynchronous version would be able to return a failure if it wasn't able
to run the calculation.

# How to run
```
iex
iex> c("parallel.ex")
iex> Parallel.run_tests
```
