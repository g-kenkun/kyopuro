defmodule Mix.Tasks.Kyopuro.Login do
  @moduledoc """
  AtCoderにログインするMixタスクです。

      $ mix kyopuro.login

  認証情報はプロンプトから入力、もしくはConfigから取得させることができます。

  Configから認証情報を取得させる場合は以下のように記載してください。パスワードはファイルに保存したくない場合は`username`のみを記載してください。

  ```elixir
  # in config/config.exs
  import Config

  config :kyopuro,
    username: "hogehoge",
    password: "hugahuga"
  ```

  Configから認証情報を取得できない場合はプロンプトから入力を求められます。

  ログインに失敗した趣旨のメッセージが表示された場合は、認証情報を確認の上再度実行してください。
  """

  use Mix.Task

  @requirements ["app.start"]
  @impl Mix.Task
  def run(_argv) do
    Kyopuro.login()
  end
end
