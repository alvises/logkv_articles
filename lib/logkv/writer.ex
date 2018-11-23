defmodule LogKV.Writer do
  use GenServer

  @moduledoc ~S"""
  In this first version, we just want to see how the mapping between the `Writer` and the `Index` works.
  We just open a file, appending on it using just one writer with one file, without using segments and 
  compaction (which we'll see in future implementations).
  """

  @doc ~S"""
  It creates the file `log_path` if doesn't exist and it truncates it otherwise. 
  When the server process starts, the file will be opened with `:write` and `:binary` flags.

  `Writer` will use the `LogKV.Index` to update the `key`'s `{offset, size}`. You need first to start the
  the `LogKV.Index` process and then you can start the `LogKV.Writer` process.

  Right now, we want to use just one Writer, so we make it uniquely available forcing it's name to __MODULE__, 
  which is the default option. We keep the options changeble to be able to run multiple tests with multiple writers 
  in parallel.

  """
  def start_link(log_path, options \\ [name: __MODULE__]) do
    GenServer.start_link(__MODULE__, log_path, options)
  end

  # the state will be %{fd: file_pid, current_offset: 0}. The writer uses the current_offset to 
  # know the absolute offset and update the index
  def init(log_path) do
    fd = File.open!(log_path, [:write, :binary])
    {:ok, %{fd: fd, current_offset: 0}}
  end
end
