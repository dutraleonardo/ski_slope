defmodule Mix.Tasks.Main do
  alias SkiSlope.{Elevator, Skier}
  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")

    # inicia o daemon dos esquiadores
    Skier.start_processing()

    # inicia o elevador
    Elevator.start_elevator()
  end
end
