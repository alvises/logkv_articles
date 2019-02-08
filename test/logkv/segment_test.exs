defmodule LogKV.SegmentTest do
  use ExUnit.Case
  doctest LogKV.Segment
  alias LogKV.Segment

  describe "new/1" do
    test "active by default" do
      assert %Segment{active: true} = Segment.new(1)
    end
  end

  describe "kv_to_binary" do

    test "CRC-32 checksum in first 4 bytes uint64 big-endian" do
      {data, _, _, _ , _} = Segment.kv_to_binary("key", "value")

      <<crc::big-unsigned-integer-size(32), kv_data::binary>> = data

      assert crc == :erlang.crc32(kv_data)
    end

    test "timestamp in 8 bytes uint64 big-endian, after CRC-32" do
      # milliseconds
      timestamp = 1_544_745_758_000
      {data, _, _, _,crc} = Segment.kv_to_binary("key", "value", timestamp)

      assert <<^crc::big-unsigned-integer-size(32),^timestamp::big-unsigned-integer-size(64), _::binary>> = data
    end

  end
end
