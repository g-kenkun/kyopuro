# Kyopuro

AtCoder用のmixタスクを提供するパッケージです。このパッケージはモジュールの生成とテストケースの生成、提出を行うmixタスクを提供します。

---

## インストール

`deps`への追加と`mix deps.get`を実行してください。

```elixir
def deps do
  [
    {:kyopuro, "~> 0.6.0"}
  ]
end
```

---

## 使い方

過去バージョンでは[AtCoder](https://atcoder.jp/)と[YukiCoder](https://yukicoder.me/)に対応していましたが、現バージョンではAtCoderのみ対応しています。

## AtCoder

### Login - ログイン

最初に`mix kyopuro.login`を実行します。

    $ mix kyopuro.login

認証情報はプロンプトから入力、もしくはConfigから取得させることができます。

Configから認証情報を取得させる場合は以下のように記載してください。

```elixir
# in config/config.exs
import Config

config :kyopuro,
  username: "hogehoge",
  password: "hugahuga"
```

ログインに失敗した趣旨のメッセージが表示された場合は、認証情報を確認の上再度実行してください。
  
### Generate module & test - モジュールとテストの生成

ログインが完了したら`mix kyopuro.new`を実行してモジュールとテストを生成することができます。

    $ mix kyopuro.new

コマンドを実行すると選択肢が表示されるので指示に従いコンテストと問題を選択してください。

ABC100を選択した場合モジュールとテストは以下のように生成されます。

```
 ┬ lib - hoge - abc100 ┬ a.ex
 │                     ├ b.ex
 │                     ├ c.ex
 │                     └ d.ex
 │
 └ test - hoge_test - abc100 ┬ a_test.exs
                             ├ b_test.exs
                             ├ c_test.exs
                             └ d_test.exs
```

### Running Tests - テストの実行

テストを実行するには`mix test <ファイルパス>`を使用します。

例としてABC100のA問題のテストを実施するには以下のようなコマンドになります。

    $ mix test test/hoge_test/abc100/a_test.exs

### Submit - 提出

提出するには`mix kyopuro.submit <ファイルパス>`を使用します。

例としてABC100のA問題を提出するコマンドは以下のようになります。

    $ mix kyopuro.submit lib/hoge/abc001/a.ex

複数提出したい場合は連続してファイルパスを指定することで提出できます。

    $ mix kyopuro.submit lib/hoge/abc001/a.ex lib/hoge/abc001/b.ex

ファイルパスは単なる前方一致なので、以下のように指定すればlib/hoge/abc001配下のファイルをすべて提出することができます。

    $ mix kyopuro.submit lib/hoge/abc001

> #### 注意事項 {: .error}
>
> 提出に必要な情報は`mix kyopuro.new`を実行したときに生成される`mapping`が持っているため、そこに記載のないファイルのパスを指定しても提出されません。手動で作成したモジュールを提出したい場合は`mapping`を手動で編集してください。

### Template - テンプレート

生成するモジュールやテストコードのテンプレートをカスタマイズすることができます。必要な

```elixir
# in config/config.exs
import Config

config :kyopuro,
    module_template: "#{module_template_file_path}"
```

## コントリビュート

適当にIssueを立てていただいたり、PRを作成していただいて構いません。