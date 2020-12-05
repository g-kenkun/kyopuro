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

  @base_switch []
  @at_coder_switch @base_switch
  @yuki_coder_switch @base_switch

  def run(args) do
    Mix.Task.run("app.start")

    adapter = Application.get_env(:kyopuro, :adapter, Kyopuro.AtCoder)

    case adapter do
      Kyopuro.AtCoder ->
        OptionParser.parse(args, switches: @at_coder_switch)

      Kyopuro.YukiCoder ->
        OptionParser.parse(args, switches: @yuki_coder_switch)
    end
    |> case do
      {_opts, [], _} ->
        Mix.Tasks.Help.run(["kyopuro.submit"])

      {opts, args, _} ->
        adapter.submit(args, opts)
    end
  end
end
