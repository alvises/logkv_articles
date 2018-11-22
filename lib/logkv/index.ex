defmodule LogKV.Index do
  use GenServer

  @doc ~S"""
  At the beginning the index will be empty. The first super-simple implementation 
  doesn't recover the index. For this version we just need one `Writer` and one `Index` and then they
  both have a name
  """
  def start_link(:empty) do
    GenServer.start_link(__MODULE__, :empty, name: __MODULE__)
  end

  # empty index
  def init(:empty), do: {:ok, %{}}

  @doc ~S"""
  Updates the index for a specific `key`. It saves the `offset` and `size` 
  of the value in the log file.

  The update is made doing a `GenServer.call`, so it's synchronous and 
  you have then the guarantee that the next `lookup` message will be able to 
  get the updated offset/size for that key.

  ## Examples

    iex> {:ok, _index} = LogKV.Index.start_link(:empty)
    iex> LogKV.Index.update("my_key", 0, 10)
    :ok

  """
  def update(key, offset, size) do
    GenServer.call(__MODULE__, {:update, key, offset, size})
  end

  @doc ~S"""
  Gets a `tuple` with `offset` and `size`  for a specific `key`.

  ### Examples

    iex> {:ok, _index} = LogKV.Index.start_link(:empty)
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
