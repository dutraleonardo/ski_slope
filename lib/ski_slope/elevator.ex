defmodule SkiSlope.Elevator do
  @moduledoc """
  Esse módulo é responsável por carregar o elevador com esquiadores das respectivas filas
  """

  use GenServer

  alias SkiSlope.QueueOperations

  require Logger

  def init(_) do
    state = %{
      counter: 0,
      single: :rs
    }
    {:ok, state}
  end

  def start_link(_) do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def start_elevator() do
    GenServer.cast(__MODULE__, :start)
  end

  def handle_cast(:start, state) do
    schedule_elevator()
    {:noreply, state}
  end

  def handle_info(:start, state) do
    state = %{state | counter: state.counter + 1}
    Logger.info("Elevador ##{state.counter} está sendo preenchido")
    state = fill(state)
    Logger.info("Elevador ##{state.counter} está partindo...")
    schedule_elevator()
    {:noreply, state}
  end

  def handle_info(:quit, state) do
    lt = QueueOperations.lookup_mean(:lt)
    rt = QueueOperations.lookup_mean(:rt)
    ls = QueueOperations.lookup_mean(:ls)
    rs = QueueOperations.lookup_mean(:rs)
    total = (lt + rt + ls + rs) / 4
    Logger.info("Média de tempo de espera em LT: #{lt}")
    Logger.info("Média de tempo de espera em RT: #{rt}")
    Logger.info("Média de tempo de espera em LS: #{ls}")
    Logger.info("Média de tempo de espera em RS: #{rs}")
    Logger.info("Média de espera total: #{total}")
    {:noreply, state}
  end

  def fill(state) do
    cond do
      QueueOperations.lookup(:lt) >= 3 ->
        Logger.info("Escolhendo esquiadores de LT e #{String.upcase(Atom.to_string(state.single))}")
        new_state = %{state | single: fill_single(state.single)}
        QueueOperations.remove_three(:lt)
        QueueOperations.remove_one(state.single)
        new_state
      QueueOperations.lookup(:rt) >= 3 ->
        Logger.info("Escolhendo esquiadores de RT e #{String.upcase(Atom.to_string(state.single))}")
        new_state = %{state | single: fill_single(state.single)}
        QueueOperations.remove_three(:rt)
        QueueOperations.remove_one(state.single)
        new_state
      (QueueOperations.lookup(:rt) < 3) && (QueueOperations.lookup(:lt) < 3) ->
        Logger.info("Escolhendo esquiadores de LS e RS")
        QueueOperations.remove_two(:ls)
        QueueOperations.remove_two(:rs)
        state
    end
  end

  defp fill_single(last_queue) do
    case last_queue do
      :ls ->
        :rs
      :rs ->
        :ls
    end
  end

  def schedule_elevator() do
    status = :ets.lookup_element(:status, "done", 2)
    if status == true && QueueOperations.all_clear == :ok do
      Process.send_after(self(), :quit, 1_000)
    else
      Process.send_after(self(), :start, 5_000)
    end
  end
end
