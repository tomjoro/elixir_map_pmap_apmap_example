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

Elixir is side effect free,  and so the anonymous function cannot affect the context it is run in. 
It doesn't really matter if it is run synchronously or asynchronously. But what if you want to run it asynchronously? 
That's easy, just spawn a process, give it the function, and have the process send you a message when it is done.
What if you don't want to wait for the answer? If you don't want to wait for the answer, then don't wait.
Summary:
  * If you pass a function to some other piece of code, it can be run synchronously or asynchronously.
  * If you need an immediate result, then it's either run in-process (synchronous), or in another process, but you'll need to wait.
  * You decide when to wait, and what to wait for. You can ignore waiting, or combine waits, etc.
  * Data is immutable, so the function can't change your context that the function was created in.


there is only one execution path
for an asynchronous job: messages sent to your process which can then handle when it wants to.

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

The idea behind this is simple: If the result is going to be calculatable quicly, then I'll wait for it.
Otherwise notifiy me when the result is ready.

For example, you have a website that does some calculation for the user. If the calculation result is 
obtainable quickly, then just do it and return it to the user. If it looks like it is going to take a while, 
then tell the user "please check back in a few seconds" - or better yet, send them a message via websockets
when the result is ready.

This same technique works for things like processing queues. If nothing is ahead of your task in a queue, 
then you can run it immediately. If the queue is long, then tell the user to check back later. This is actually
how the Logger works. You don't want your code to slow down, just because the disk is temporarily slow, but most
of the time you would like to know that the logger completed your task.


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
