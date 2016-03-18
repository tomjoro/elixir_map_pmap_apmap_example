defmodule Parallel do
  @moduledoc """

  This module shows how you can hide the synchronous and asynchronous behaviour
  behind an API.

  """


  @doc """
    This shows a common technique in Elixir/Erlang. If something is fast, do
    it synchronous (either in process or multi-process), and it looks like
    a big problem, then do it asynchronous, which lets the caller do other
    work and check back later for the result.

    Runs a parallel map by either a) in current process, b) synchronous multi-process or
    c) fully asynchronous multi-process, and you need to wait for result.

    It chooses which one to run based on the size of the collection.

    Only works with ranges currently.

  ## Parameters
    - range: a collection that can be enumerated
    - function: an anonymous function to apply to each element in collection

  ## Examples
    iex> Parallel.map_or_pmap_or_apmap((0..4), fn(x) -> x * x end)
    [0, 1, 4, 9, 16]
  """
  def map_or_pmap_or_apmap(%Range{} = range, function) do
    me = self
    first..last = range
    result = case last - first do
        x when x > 1000 ->
                          IO.puts("<delayed_pmap>")
                          pid = spawn_link( fn -> pmap_wrapper(me, range, function) end)
                          {:delayed, pid}
        x when x > 100 ->
          IO.puts("<pmap>")
          {:ok, pmap(range, fn(x) -> x * x end) }
        _ ->
          IO.puts("<normal map>")
          {:ok, Enum.map(range, fn(x) -> x * x end) }
    end
    result
  end

  def map_or_pmap(%Range{} = range, function) do
    first..last = range
    result = case last - first > 1000 do
        true -> pmap(range, function)
        _ -> Enum.map((0..100000), fn(x) -> x * x end)
    end
    result
  end

  @doc """
  runs a parallel map by spawning a bunch of processes and returns array of results
  ## Parameters
    - collection: a collection that can be enumerated
    - function: an anonymous function to apply to each element in collection

  ## Examples
    iex> Parallel.pmap((0..4), fn(x) -> x * x end)
    [0, 1, 4, 9, 16]
  """
  def pmap(collection, function) do
    me = self
    pid_list = Enum.map(collection, fn (elem) ->
      spawn_link fn -> (send me, { self, function.(elem) }) end
    end)
    Enum.map(pid_list, fn (pid) ->
      receive do { ^pid, result } -> result end
    end)
  end

  def pmap_wrapper(me, collection, function) do
    result = pmap(collection, function)
    send me, {self, result}
  end

  def map(collection, function) do
    Enum.map(collection, function)
  end

  def handle_result(result = {:delayed, pid}) do
    IO.puts(">> Running asynchronously, I am not going to wait for results:")
    waiting(pid)
  end

  def handle_result(result = {:ok, arr}) do
    IO.puts(">> Ran synchronously, here are the results:")
    IO.inspect(arr)
  end

  def run_fail_test do
    [0, 1, 3, 9, 16 ] = Parallel.pmap((0..4), fn(x) -> x * x end)           # multi-process
  end

  def run_tests do
    IO.puts "------map:"
    IO.inspect Parallel.map((0..100000), fn(x) -> x * x end)            # single-process
    IO.puts "------pmap"
    IO.inspect Parallel.pmap((0..4), fn(x) -> x * x end)           # multi-process
    IO.puts "------map_or_pmap use multi-process"
    IO.inspect Parallel.map_or_pmap((0..100000), fn(x) -> x * x end)    # use multi-process
    IO.puts "------map_or_pmap use this (one) process"
    IO.inspect Parallel.map_or_pmap((0..100), fn(x) -> x * x end)     # use single-process

    IO.puts "checking the 3 versions"

    # But what if you  only want to wait if it is a BIG one...
    Parallel.handle_result(Parallel.map_or_pmap_or_apmap((0..10), fn(x) -> x * x end))
    Parallel.handle_result(Parallel.map_or_pmap_or_apmap((0..150), fn(x) -> x * x end))
    Parallel.handle_result(Parallel.map_or_pmap_or_apmap((0..1000000), fn(x) -> x * x end))
  end

  def waiting(pid) do
    receive do
      { ^pid, result } -> IO.puts("Results have ready. Yay!:")
                          IO.inspect(result)
    after
      1_000 -> IO.puts "still waiting... more hamsters needed..."
      waiting(pid)
    end
  end

end
