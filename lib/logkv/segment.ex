defmodule LogKV.Segment do
  alias __MODULE__

  @doc ~S"""
  A segment represents a single log-file. One only segment is active for writing at a time.
    :id is the id of the segment
    :active true if the segment is active for writing
    :current_offset is used when appending (active: true)
    :fd_w  file pid opened in :write, :binary
  """
  @enforce_keys [:id, :active]
  defstruct [:id, :active, :current_offset, :fd_w]

  def new(id\\0) do
    %Segment{id: id, active: true, current_offset: 0}
  end


  @doc ~S"""
  Part-3: Tansforms the integer representing the size of the key and the value in bytes.
  The size of the key is represented by a 16bit unsigned integer,  this means can be maximum around 65kb, which for this example is more then enough.
  We use a 32bit unsigned int to represent the value size, which means the maximum size of the value is 4.29GB. If someone needs to use more 4GB maybe it's
  better to use the filesystem directly as a kv store.
  *big-unsigned-integer-size(16)* means the integer is converted to a binary of 2bytes big endian order.
  If you want to know what endianess is, please look here: https://en.wikipedia.org/wiki/Endianness

    ## Examples

      iex> {data, key_size, value_rel_offset, value_size} = LogKV.Segment.kv_to_binary(:os.system_time(:millisecond), "key", "value")
      iex> byte_size(data)
      22
      iex> key_size
      3
      iex> value_rel_offset
      17
      iex> value_size
      5

  """
  def kv_to_binary(timestamp, key, value) do
    # conversion of an integer to big endian 16bit unisigned integer.
    #
    # << our_int :: conversion from integer to binary >>

    # timestamp = :os.system_time(:millisecond)
    timestamp_data = <<timestamp::big-unsigned-integer-size(64)>>

    key_size = byte_size(key)
    value_size = byte_size(value)

    key_size_data = <<key_size::big-unsigned-integer-size(16)>>
    value_size_data = <<value_size::big-unsigned-integer-size(32)>>

    # sizes_data is a 6bytes binary with first 2 bytes the key size and then 4 bytes for the value size.
    sizes_data = <<key_size_data::binary, value_size_data::binary>>

    # kv_data is just the concatenation of the key and value
    kv_data = <<key::binary, value::binary>>

    # we then create a single entry which comprehends timestamp, key and values sizes, key and the value.
    data = <<timestamp_data::binary, sizes_data::binary, kv_data::binary>>

    # we then return a tuple with the entry data, key size, value relative offset, which is where the value is located in *data* binary, and value size.
    # 8 bytes of timesamp
    # 2 bytes of key size
    # 4 bytes of value size
    # key_size bytes of key
    value_rel_offset = byte_size(timestamp_data) + byte_size(sizes_data) + key_size

    {data, key_size, value_rel_offset, value_size}
  end

end
