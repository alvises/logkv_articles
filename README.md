Part 1
===
# LogKV

Code of the first implementation explained in the article [Build a simple persistent key-value store in Elixir, using logs - Part 1](https://www.poeticoding.com/build-a-simple-persistent-key-value-store-in-elixir-using-logs-part-1)

> _The code in this article is heavily inspired from the concepts amazingly explained in the book_ [Designing Data-Intensive Applications](https://dataintensive.net) _by_ [_Martin Kleppmann_](https://medium.com/u/13be457aed12)_._

>  **_Disclaimer_**_, all the code you find in this article, and on the github repo, is written for pure fun and meant just as an experiment._

In this series of articles we will see the different concepts behind a key-values store (Logs, Segments, Compaction, Memtable, SSTable) implementing a simple engine in Elixir, which is a great language to build highly-concurrent and fault-tolerant architectures. 

In this first part we will see:
* What is a log?
* Making a KV persistent using a log and an index. Using an example we will use along the series, (crypto market prices and trades),  we are going to see how to store the values in a log using using an index.
* LogKV in Elixir. A initial super simple implementation in elixir of a Writer, an Index and a Reader.


## How to use it
```elixir
iex> LogKV.Index.start_link([])
iex> LogKV.Writer.start_link("test.db")
{:ok, #PID<0.197.0>}
iex> {:ok, pid} = LogKV.Reader.start_link("test.db")
iex> LogKV.Reader.get(pid, "btc")
{:ok, "4411.99"}
```

## What's next
There are obviously different issues like

* The index is kept in memory. The memory then limits the number of keys we can have in our storage engine.

* If our storage engine crashes, we loose the index (which is only in memory) without being able to recover the data. This can be fixed appending the keys along with the value. In this way we are able to recover the index scanning the log file.

* The log grows indefinitely keeping the old values. We need to first put a cap to the log size and to get rid of the old values. This leads to important concepts like **segments** and  **compaction**.

In the next parts we will dig into these issues expanding the implementation of our storage engine.



Part 2
===

[Build a simple persistent key-value store in Elixir, using logs - Part 2](https://www.poeticoding.com/build-a-simple-persistent-key-value-store-in-elixir-using-logs-part-2)

In this second part we'll do a step further, making both keys and values persistent, to be able to recover the Index in the case of a failure.  We we also see how to start the Index, Writer and Reader inside a supervision tree.

