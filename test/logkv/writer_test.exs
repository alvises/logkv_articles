defmodule LogKV.WriterTest do
  use ExUnit.Case, async: true

  doctest LogKV.Writer

  describe "start_link/2" do
    setup do
      log_path = Temp.path!()
      on_exit(fn -> File.rm!(log_path) end)

      %{log_path: log_path}
    end

    test "create the file passed as argument", %{log_path: log_path} do
      # in this way we don't register any name for this process
      {:ok, _pid} = LogKV.Writer.start_link(log_path, [])

      assert File.exists?(log_path)
    end

    test "only one writer", %{log_path: log_path} do
      # the name of the process will be the default one, LogKV.Writer
      {:ok, _} = LogKV.Writer.start_link(log_path)
      assert File.exists?(log_path)

      second_log_path = "#{log_path}.2"
      assert {:error, {:already_started, _}} = LogKV.Writer.start_link(second_log_path)
      assert not File.exists?(second_log_path)
    end
  end

  # describe "put/3" 
end
