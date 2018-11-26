defmodule LogKV.Reader do
  use GenServer

  @moduledoc ~S"""
  The Reader reads gets the value of a given `key`, from the log-file.
  """

  @doc ~S"""
  You need first to start `LogKV.Index` and `LogKV.Writer` in this order. 
  The reader doens't have the name fixed, because we can have multiple readers for one single log-file.
  """

  def start_link(log_path) do
    GenServer.start_link(__MODULE__, log_path)
  end

  @doc ~S"""
  The reader just needs the file opened. The file process is saved in the state
  """
  def init(log_path) do
    fd = File.open!(log_path, [:read, :binary])
    {:ok, %{fd: fd}}
  end

  @doc ~S"""
  {:ok, value}
  {:error, :not_found}
  """
  def get(pid, key) do
    GenServer.call(pid, {:get, key})
  end

  def handle_call({:get, key}, _from, %{fd: fd} = state) do
    # We use :file.pread/3 which makes a seek to the offset and then reads 
    # the number of bytes we need.
    # It returns `{:ok, data}` when all goes well and {:error, reason} otherwise.
    # http://erlang.org/doc/man/file.html#pread-3
    case LogKV.Index.lookup(key) do
      {:ok, {offset, size}} ->
        {:reply, :file.pread(fd, offset, size), state}

      {:error, _} = error ->
        {:reply, error, state}
    end
  end
end
