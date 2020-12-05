defmodule Mix.Tasks.Kyopuro.Login do
  @moduledoc """
  First, run the `mix kyopuro.login`.

  最初に`mix kyopuro.login`を実行します。

    $ mix kyopuro.login

  By default, it reads the login information from the configuration file.

  デフォルトではコンフィグファイルからログイン情報を読み取ります。

  ```elixir
  # in config/config.exs

  config :kyopuro,
    username: "hogehoge",
    password: "hugahuga"
  ```

  You can use the `--i` or `--interactive` option to enable interactive login.

  `-i`もしくは`--interactive`オプションを使用すれば対話形式でのログインができます。

    $ mix kyopuro.login -i
    or
    $ mix kyopuro.login --interactive

  If you get a 403 error, please try again.

  もし403エラーが出た場合は再度実行してください。
  """

  use Mix.Task

  @aliases [i: :interactive, u: :username, p: :password]
  @switches [interactive: :boolean, username: :string, password: :string]
  @at_coder_switches @switches

  def run(args) do
    Mix.Task.run("app.start")

    adapter = Application.get_env(:kyopuro, :adapter, Kyopuro.AtCoder)

    {opts, args, _} =
      case adapter do
        Kyopuro.AtCoder ->
          OptionParser.parse(args, switches: @at_coder_switches)

        Kyopuro.YukiCoder ->
          Mix.raise(
            "For YukiCoder you do not need to login. Instead, put the API Key in your config."
          )
      end

    Kyopuro.AtCoder.login(args, opts)
  end
end
