defmodule SkiSlope.QueueOperations do
  @moduledoc false

  require Logger

  @table_key "queue"

  def add_one(table) do
    :ets.update_counter(table, @table_key, {2, 1}, {@table_key, 0})
    Logger.info("Um esquiador adicionado a fila #{String.upcase(Atom.to_string(table))}")
  end

  def remove_one(table) do
    :ets.update_counter(table, @table_key, {2, -1}, {@table_key, 0})
    update_waiting_time(table)
    Logger.info("Um esquiador removido da fila #{String.upcase(Atom.to_string(table))}")
  end

  def remove_two(table) do
    :ets.update_counter(table, @table_key, {2, -2}, {@table_key, 0})
    update_waiting_time(table)
  end

  def remove_three(table) do
    :ets.update_counter(table, @table_key, {2, -3}, {@table_key, 0})
    update_waiting_time(table)
    Logger.info("Três esquiadores removidos da fila #{String.upcase(Atom.to_string(table))}")
  end

  def update_waiting_time(table) do
    last = lookup_stats_last(table)
    value = DateTime.diff(DateTime.now!("Etc/UTC"), last)
    update_mean(table, value)
  end

  def lookup(table) do
    case :ets.lookup(table, @table_key) do
      [] ->
        0

      _ ->
        :ets.lookup_element(table, @table_key, 2)
    end
  end

  def insert_last(:lt), do: :ets.insert(:mean_lt, {"last", DateTime.now!("Etc/UTC")})

  def insert_last(:rt), do: :ets.insert(:mean_rt, {"last", DateTime.now!("Etc/UTC")})

  def insert_last(:rs), do: :ets.insert(:mean_rs, {"last", DateTime.now!("Etc/UTC")})

  def insert_last(:ls), do: :ets.insert(:mean_ls, {"last", DateTime.now!("Etc/UTC")})

  def insert_time(:ls), do: :ets.insert(:mean_ls, {"last", DateTime.now!("Etc/UTC")})

  def all_clear() do
    cond do
      Enum.sum([lookup(:lt), lookup(:rt), lookup(:ls), lookup(:rs)]) <= 0 ->
        :ok
      true ->
        :none
    end
  end

  def lookup_stats_last(:lt), do: :ets.lookup_element(:mean_lt, "last", 2)

  def lookup_stats_last(:rt), do: :ets.lookup_element(:mean_rt, "last", 2)

  def lookup_stats_last(:rs), do: :ets.lookup_element(:mean_rs, "last", 2)

  def lookup_stats_last(:ls), do: :ets.lookup_element(:mean_ls, "last", 2)

  def update_mean(:lt, value), do: :ets.insert(:mean_lt, {"mean", value})

  def update_mean(:rt, value), do: :ets.insert(:mean_rt, {"mean", value})

  def update_mean(:rs, value), do: :ets.insert(:mean_rs, {"mean", value})

  def update_mean(:ls, value), do: :ets.insert(:mean_ls, {"mean", value})

  def lookup_mean(:lt), do: :ets.lookup_element(:mean_lt, "mean", 2)

  def lookup_mean(:rt), do: :ets.lookup_element(:mean_rt, "mean", 2)

  def lookup_mean(:rs), do: :ets.lookup_element(:mean_rs, "mean", 2)

  def lookup_mean(:ls), do: :ets.lookup_element(:mean_ls, "mean", 2)
end
