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

  @base_switches [only_module: :boolean, only_test: :boolean]
  @at_coder_switches @base_switches
  @yuki_coder_switches @base_switches ++ [contest: :string, problem: :string]

  def run(args) do
    Mix.Task.run("app.start")

    adapter = Application.get_env(:kyopuro, :adapter, Kyopuro.AtCoder)

    {opts, args, _} =
      case adapter do
        Kyopuro.AtCoder ->
          OptionParser.parse(args, switches: @at_coder_switches)

        Kyopuro.YukiCoder ->
          OptionParser.parse(args, switches: @yuki_coder_switches)
      end

      adapter.new(args, opts)
      |> Enum.map(&Kyopuro.put_binding/1)
      |> Enum.map(&Kyopuro.generate/1)
  end
end
