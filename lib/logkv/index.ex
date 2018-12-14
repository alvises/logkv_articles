defmodule LogKV.Index do
  use GenServer

  @doc ~S"""
  At the beginning the index will be empty. The first super-simple implementation
  doesn't recover the index. For this version we just need one index process with `LogKV.Index`
  name.
  """
  def start_link(:empty) do
    GenServer.start_link(__MODULE__, :empty, name: __MODULE__)
  end

  def start_link(log_path) when is_binary(log_path) do
    GenServer.start_link(__MODULE__, log_path, name: __MODULE__)
  end

  # empty index
  def init(:empty), do: {:ok, %{}}

  @doc ~S"""
  Part-2: Recovers the inde
  """
  def init(log_path) do
    with {:ok, fd} <- File.open(log_path, [:read, :binary]),
         {_current_offset, offsets} = load_offsets(fd) do
      File.close(fd)
      {:ok, offsets}
    else
      _ -> init(:empty)
    end
  end

  defp load_offsets(fd, offsets \\ %{}, current_offset \\ 0) do
    :file.position(fd, current_offset)

    with <<_timestamp::big-unsigned-integer-size(64)>> <- IO.binread(fd, 8),
         <<key_size::big-unsigned-integer-size(16)>> <- IO.binread(fd, 2),
         <<value_size::big-unsigned-integer-size(32)>> <- IO.binread(fd, 4),
         key <- IO.binread(fd, key_size) do
      # updating the current_offset to jump at the beginning of the next entry
      value_abs_offset = current_offset + 14 + key_size

      offsets = Map.put(offsets, key, {value_abs_offset, value_size})

      load_offsets(fd, offsets, value_abs_offset + value_size)
    else
      :eof -> {current_offset, offsets}
    end
  end

  @doc ~S"""
  Updates the index for a specific `key`. It saves the `offset` and `size`
  of the value in the log file.

  The update is made doing a `GenServer.call`, so it's synchronous and
  you have then the guarantee that the next `lookup` message will be able to
  get the updated offset/size for that key.

  There is a strong coupling here, useful to make this example/implementation simple.
  Instead of giving the option, via the interface, of sending the message to a specified process,
  with this method we can only send messages to the process named `LogKV.Index`.

  ## Examples

    iex> {:ok, _index_pid} = LogKV.Index.start_link(:empty)
    iex> LogKV.Index.update("my_key", 0, 10)
    :ok

  """
  def update(key, offset, size) do
    GenServer.call(__MODULE__, {:update, key, offset, size})
  end

  @doc ~S"""
  Gets a `tuple` with `offset` and `size`  for a specific `key`.

  ### Examples

    iex> {:ok, _index_pid} = LogKV.Index.start_link(:empty)
    iex> {:error, :not_found} = LogKV.Index.lookup("not_existing_key")
    iex> LogKV.Index.update("btc",10,6)
    :ok
    iex> LogKV.Index.lookup("btc")
    {:ok, {10, 6}}


  """
  def lookup(key) do
    GenServer.call(__MODULE__, {:lookup, key})
  end

  def handle_call({:update, key, offset, size}, _from, index_map) do
    {:reply, :ok, Map.put(index_map, key, {offset, size})}
  end

  def handle_call({:lookup, key}, _from, index_map) do
    {:reply, get_key_offset_size(key, index_map), index_map}
  end

  # if the key exists returns {:ok, {offset, size}} if the keys is found.
  # if key is not found returns {:error, :not_found}
  defp get_key_offset_size(key, index_map) do
    case Map.get(index_map, key) do
      {_offset, _size} = offset_size -> {:ok, offset_size}
      nil -> {:error, :not_found}
    end
  end
end
