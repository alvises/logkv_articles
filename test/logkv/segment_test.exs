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
    test "timestamp in the first 8 bytes, uint64 big-endian" do
      # milliseconds
      timestamp = 1_544_745_758_000
      {data, _, _, _} = Segment.kv_to_binary("key", "value", timestamp)

      assert <<^timestamp::big-unsigned-integer-size(64), _::binary>> = data
    end
  end
end
