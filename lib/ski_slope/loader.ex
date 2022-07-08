defmodule SkiSlope.Loader do
  @moduledoc """
  Este módulo é responsável por carregar os esquiadores nas suas respectivas filas.
  """

  use GenServer

  alias SkiSlope.QueueOperations

  require Logger

  @queues [:lt, :rt, :ls, :rs]
  @states [:mean_lt, :mean_rt, :mean_ls, :mean_rs]
  @table_key "queue"
  def init(_) do
    start_queues()
    start_states()
    {:ok, nil}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  defp start_queues() do
    Enum.each(@queues, fn table ->
      :ets.new(table, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
    end
    )
  end

  defp start_states() do
    Enum.each(@states, fn table ->
      :ets.new(table, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
    end
    )
  end

  def add() do
    GenServer.call(__MODULE__, :create)
  end

  def update_counter(table) do
    :ets.update_counter(table, @table_key, {2, 1}, {@table_key, 0})
    Logger.info("Esquiador adicionado a fila #{String.upcase(Atom.to_string(table))}")
  end

  def handle_call(:create, _from, state) do
    queue = choose_queue()
    QueueOperations.add_one(queue)
    QueueOperations.insert_last(queue)
    now = DateTime.now!("Etc/UTC")
    Logger.info("Fila selecionada #{String.upcase(Atom.to_string(queue))}")
    {:reply, now, state}
  end

  def choose_queue() do
    len_lt = QueueOperations.lookup(:lt)
    len_rt = QueueOperations.lookup(:rt)
    len_rs = QueueOperations.lookup(:rs)
    len_ls = QueueOperations.lookup(:ls)

    cond do
      len_ls < 2 * len_lt && len_ls < 2 * len_rt && len_ls < len_rs ->
        :ls
      len_rs < 2 * len_lt && len_rs < 2 * len_rt && len_rs <= len_ls ->
        :rs
      len_lt <= len_rt ->
        :lt
      true ->
        :rt
    end
  end
end
