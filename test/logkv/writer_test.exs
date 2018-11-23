defmodule LogKV.WriterTest do
  use ExUnit.Case, async: true

  doctest LogKV.Writer

  describe "start_link/1" do
    setup do
      log_path = Temp.path!()
      on_exit(fn -> File.rm!(log_path) end)

      %{log_path: log_path}
    end

    test "create the file passed as argument", %{log_path: log_path} do
      {:ok, _pid} = LogKV.Writer.start_link(log_path)
      assert File.exists?(log_path)
    end

    # test "only one writer" do
    # end
  end
end
