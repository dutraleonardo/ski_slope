defmodule Mix.Tasks.Main do
  alias SkiSlope.{Elevator, Skier}
  use Mix.Task

  def run(_) do
    Mix.Task.run("app.start")
    Skier.start_processing()
    Elevator.start_elevator()
  end
end
