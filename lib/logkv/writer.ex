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

  `Writer` will send messages to the index process to update the `key`'s `{offset, size}`. You need first to start the
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

  @doc ~S"""
  Puts the given `value` under `key` in the kv-storage engine. The `value` needs to be a binary.

  The `Writer` appends the `value` and send an update message to the `Index` process.
  The function is synchronous, when it returns successfully you  have the guarantee that the value is in the log
  and the index is updated.

  """
  def put(pid, key, value) when is_binary(value) do
    GenServer.call(pid, {:put, key, value})
  end

  def handle_call({:put, key, value}, _from, %{fd: fd, current_offset: current_offset} = state) do
    # no particular error handling, we are just experimenting.
    :ok = IO.binwrite(fd, value)
    size = byte_size(value)

    LogKV.Index.update(key, current_offset, size)

    new_state = %{state | current_offset: current_offset + size}
    {:reply, {:ok, {current_offset, size}}, new_state}
  end
end
