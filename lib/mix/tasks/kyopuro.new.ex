defmodule Mix.Tasks.Kyopuro.New do
  @moduledoc """
  Once you have logged in, you can specify a contest to generate modules and tests.

  ログインが完了したらコンテストを指定してモジュールとテストを生成することができます。

    $ mix kyopuro.new ${contest_name}

  If you want to generate abc100 modules and tests, here's how it looks like.

  abc100のモジュールとテストを生成する場合は以下のようになります。

    $ mix kyopuro.new abc100

  In this case, the modules and tests will be generated as follows (if you run it in a hoge project)

  この場合モジュールとテストは以下のように生成されます。(hogeプロジェクトで実行した場合)

  ```
  ┬ lib ─ hoge ─ abc100 ─ ┬ a.ex
  │                       ├ b.ex
  │                       ├ c.ex
  │                       └ d.ex
  │
  └ test ─ hoge_test ─ abc100 ┬ a_test.exs
                             ├ b_test.exs
                             ├ c_test.exs
                             └ d_test.exs
  ```
  """

  use Mix.Task

  @switch [only_module: :boolean, only_test: :boolean]

  def run(args) do
    Mix.Task.run("app.start")

    case OptionParser.parse(args, switches: @switch) do
      {_opts, [], _} ->
        Mix.Tasks.Help.run(["kyopuro.new"])

      {opts, [contest_name | _], _} ->
        Kyopuro.AtCoder.new(contest_name, opts)
        |> Enum.map(&Kyopuro.put_binding/1)
        |> Enum.map(&Kyopuro.generate/1)
    end
  end
end
