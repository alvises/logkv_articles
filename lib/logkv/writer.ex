defmodule LogKV.Writer do
  use GenServer

  @moduledoc ~S"""
  Part-1: In this first version, we just want to see how the mapping between the `Writer` and the `Index` works.
  We just open a file, appending on it using just one writer with one file, without using segments and 
  compaction (which we'll see in future implementations).

  Part-2: We write the key and value together, with their sizes, so we can recover the index from the log file.
  We use the same entry schema of the bitcask design you can find here: http://basho.com/wp-content/uploads/2015/05/bitcask-intro.pdf, 
  we only skeep CRC error check, maybe we do it in an appendix of this article.

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
  def start_link(log_path) do
    GenServer.start_link(__MODULE__, log_path, name: __MODULE__)
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
  def put(key, value) do
    GenServer.call(__MODULE__, {:put, key, value})
  end

  def handle_call({:put, key, value}, _from, %{fd: fd, current_offset: current_offset} = state) do
    # no particular error handling here, we are just experimenting.
    :ok = IO.binwrite(fd, value)
    size = byte_size(value)

    LogKV.Index.update(key, current_offset, size)

    new_state = %{state | current_offset: current_offset + size}
    {:reply, {:ok, {current_offset, size}}, new_state}
  end

  
  @doc ~S"""
  Part-2: Tansforms the integer representing the size of the key and the value in bytes.
  The size of the key is represented by a 16bit unsigned integer,  this means can be maximum around 65kb, which for this example is more then enough.
  We use a 32bit unsigned int to represent the value size, which means the maximum size of the value is 4.29GB. If someone needs to use more 4GB maybe it's
  better to use the filesystem directly as a kv store.
  *big-unsigned-integer-size(16)* means the integer is converted to a binary of 2bytes big endian order. 
  If you want to know what endianess is, please look here: https://en.wikipedia.org/wiki/Endianness

    ## Examples

      iex> {_data, key_size, value_size} = LogKV.Writer.kv_to_binary(:os.system_time(:millisecond), "key", "value")
      iex> key_size
      <<0, 3>>
      iex> value_size
      <<0, 0, 0, 5>>

  """
  def kv_to_binary(timestamp,key, value) do

    #conversion of an integer to big endian 16bit unisigned integer. 
    # 
    # << our_int :: conversion from integer to binary >>

    # timestamp = :os.system_time(:millisecond)
    timestamp_data = <<timestamp::big-unsigned-integer-size(64)>>

    key_size = <<byte_size(key)::big-unsigned-integer-size(16)>>
    value_size = <<byte_size(value)::big-unsigned-integer-size(32)>>

    # sizes_data is a 6bytes binary with first 2 bytes the key size and then 4 bytes for the value size.
    sizes_data = <<key_size::binary, value_size::binary>>

    #kv_data is just the concatenation of the key and value
    kv_data = <<key::binary, value::binary>>

    #we then create a single entry which comprehends timestamp, key and values sizes, key and the value.
    data = <<timestamp_data::binary, sizes_data::binary, kv_data::binary>>
    
    #we then return a tuple with the entry data, key size and value size
    {data, key_size, value_size}
  end

end
