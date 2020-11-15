defmodule Mix.Tasks.Kyopuro.Submit do
  @moduledoc """
  You can submit a contest name or the name of the contest and task.

  コンテスト名もしくはコンテスト名とタスク名を指定して提出することができます。

    $ mix kyopuro.submit ${contest_name}
    or
    $ mix kyopuro.submit ${contest_name} ${module_file_name}

  If you want to generate abc100 modules and tests, this is how it looks like.

  abc100の提出をする場合は以下のようになります。

    $ mix kyopuro.submit abc100
    $ mix kyopuro.submit abc100 a

  You can give multiple task names.

  タスク名は複数与えることが可能です。

    $ mix kyopuro.submit abc100 a b c d
  """

  use Mix.Task

  @switch []

  def run(args) do
    Mix.Task.run("app.start")

    case OptionParser.parse(args, switches: @switch) do
      {_opts, [], _} ->
        Mix.Tasks.Help.run(["kyopuro.submit"])

      {opts, [contest_name | []], _} ->
        Kyopuro.AtCoder.submit(contest_name, opts)

      {opts, [contest_name | task_name_list], _} ->
        Kyopuro.AtCoder.submit(contest_name, task_name_list, opts)
    end
  end
end
