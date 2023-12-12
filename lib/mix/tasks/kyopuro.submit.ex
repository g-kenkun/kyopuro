defmodule Mix.Tasks.Kyopuro.Submit do
  @moduledoc """
  提出するMixタスクです。本Mixタスクを使用する場合は事前に`mix kyopuro.login`を実行してログインしておくことが必要です。

  提出したいファイルのパスを指定することで提出できます。例としてABC100のA問題を提出するコマンドは以下のようになります。

      $ mix kyopuro.submit lib/hoge/abc_001/a.ex

  複数提出したい場合は連続してファイルのパスを指定することで提出できます。

      $ mix kyopuro.submit lib/hoge/abc_001/a.ex lib/hoge/abc_001/b.ex

  まとめて提出したい場合はファイルのパスを途中まで指定することで提出できます。

      $ mix kyopuro.submit lib/hoge/abc_001

  > #### 注意事項 {: .error}
  >
  > 提出に必要な情報は`mix kyopuro.new`を実行したときに生成される`mapping`が持っているため、そこに記載のないファイルのパスを指定しても提出されません。手動で作成したモジュールを提出したい場合は`mapping`を手動で編集してください。
  """

  use Mix.Task

  @requirements ["app.start"]
  @impl Mix.Task
  def run(argv) do
    Kyopuro.submit(argv)
  end
end
