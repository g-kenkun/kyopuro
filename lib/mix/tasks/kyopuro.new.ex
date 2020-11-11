defmodule Mix.Tasks.Kyopuro.New do
  @moduledoc false
  @shortdoc "Mix task to generate modules and test cases from a contest"

  use Mix.Task

  @switch [only_module: :boolean, only_test: :boolean]

  def run(args) do
    Mix.Task.run("app.start")

    case OptionParser.parse(args, switches: @switch) do
      {_opts, [], _} ->
        Mix.Tasks.Help.run(["kyopuro.new"])

      {_opts, [contest_name | _], _} ->
        Kyopuro.AtCoder.new(contest_name)
        |> Enum.map(&Kyopuro.put_binding/1)
        |> Enum.map(&Kyopuro.generate/1)
    end
  end
end
