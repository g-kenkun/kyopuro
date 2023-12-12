defmodule Mix.Tasks.Kyopuro.New do
  @moduledoc """
  コンテスト/問題を指定してモジュールとテストを生成するMixタスクです。本Mixタスクを使用する場合は事前に`mix kyopuro.login`を実行してログインしておくことが必要です。

      $ mix kyopuro.new

  上記Mixタスクを実行するとコンテストを「常設中のコンテスト」「Rated対象から検索」「カテゴリから検索」「キーワードから検索」から検索するよう促されます。

      1. URLを入力
      2. 常設中のコンテスト
      3. Rated対象から検索
      4. カテゴリから検索
      5. キーワードから検索

      >

  適当に選択していくとモジュールとテストが生成されます。例としてhogeプロジェクトでABC100のA問題を選択したものを載せます。

  ```
  ┬ lib - hoge - abc100 - a.ex
  │
  └ test - hoge_test - abc100 - a_test.exs
  ```

  モジュールとテストはKyopuroで用意しているテンプレート以外にユーザー側で定義したものを使用することが可能です。

  ```elixir
  # in config/config.exs
  import Config

  config :kyopuro,
    module_template: "priv/templates/module_template.ex",
    test_template: "priv/templates/test_template.ex"
  ```

  Kyopuroで用意しているテンプレートは以下のようになっています。

  <!-- tabs-open -->

  ### モジュールのテンプレート

  ```elixir
  # モジュールのテンプレート
  defmodule <%= inspect(module) %> do
    def main do

    end
  end
  ```

  ### テストのテンプレート

  ```erlang
  defmodule <%= inspect(test_module) %> do
    use ExUnit.Case

    import ExUnit.CaptureIO
  <%= for test_case <- test_cases do %>
    test <%= inspect(Keyword.get(test_case, :input)) %> do
      assert(
        capture_io([input: <%= inspect(Keyword.get(test_case, :input)) %>, capture_prompt: false], fn ->
          <%= inspect(module) %>.main()
        end) == <%= inspect(Keyword.get(test_case, :output)) %>
      )
    end<% end %>
  end
  ```

  <!-- tabs-close -->
  """

  use Mix.Task

  @requirements ["app.start"]
  @impl Mix.Task
  def run(_argv) do
    Kyopuro.new()
  end
end
