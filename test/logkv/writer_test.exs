defmodule LogKV.WriterTest do
  use ExUnit.Case
  doctest LogKV.Writer

  describe "start_link/1" do
    test "create the file passed as argument" do
      tmp_log = Temp.path!()

      {:ok, pid} = LogKV.Writer.start_link(tmp_log)
      assert File.exists?(tmp_log)

      File.rm!(tmp_log)
    end
  end
end
