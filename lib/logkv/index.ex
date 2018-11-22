defmodule LogKV.Index do
  use GenServer

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
    GenServer.call(__MODULE__, {:set, key, offset, size})
  end

  def handle_call({:set, key, offset, size}, _from, index_map) do
    {:reply, :ok, Map.put(index_map, key, {offset, size})}
  end
end
