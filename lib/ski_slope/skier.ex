defmodule SkiSlope.Skier do
  @moduledoc """
  Este módulo é responsável por criar (spawn) processos onde cada um representa um esquiador.
  """

  use GenServer

  alias SkiSlope.Loader

  require Logger

  def start_link(_default) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end
  def init(_) do
    state = %{counter: 0}
    status_control()
    {:ok, state}
  end

  defp status_control() do
    :ets.new(:status, [:set, :named_table, :public, read_concurrency: true, write_concurrency: true])
    :ets.insert(:status, {"done", false})
  end

  def start_processing() do
    GenServer.cast(__MODULE__, :start)
  end

  def handle_cast(:start, state) do
    schedule_next_skier(state)
    {:noreply, state}
  end

  def handle_info(:new_skier, state) do
    new_state = Map.update!(state, :counter, &(&1 + 1))
    Logger.info("Esquiador número # #{new_state.counter} criado")
    Loader.add()
    schedule_next_skier(new_state)
    {:noreply, new_state}
  end

  def handle_info(:quit, state) do
    Logger.info("Quantidade máxima de esquiadores atingido: #{state.counter}")
    :ets.insert(:status, {"done", true})
    {:noreply, state}
  end

  def handle_info({:DOWN, _ref, :process, _pid, _reason}, state) do
    {:noreply, state}
  end

  # Essa função é acionada quando atinge o limite de 120 esquiadores, então uma mensagem de encerrar a criação é enviada
  def schedule_next_skier(%{counter: 120}) do
    Process.send_after(self(), :quit, 1_000)
  end

  # Essa função cria um esquiador a cada 1 segundo
  def schedule_next_skier(_state) do
    Process.send_after(self(), :new_skier, 1_000)
  end
end
