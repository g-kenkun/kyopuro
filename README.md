# Kyopuro

This package provides a mix of tasks for AtCoder and YukiCoder. This package provides mix tasks for module generation and test case generation.

AtCoderとYukiCoder用のmixタスクを提供するパッケージです。このパッケージはモジュールの生成とテストケースの生成、提出を行うmixタスクを提供します。

---

## Installation

The Meeseeks package used in this package uses Rust for Nifs, so you need to set up the Rust environment beforehand.

このパッケージで使用しているhtml5everパッケージはNifsにRustを使用しているので、予めRustの環境を構築する必要があります。

```elixir
def deps do
  [
    {:kyopuro, "~> 0.4.0"}
  ]
end
```

---

## Usage - 使い方

現在 [AtCoder](https://atcoder.jp/) と [YukiCoder](https://yukicoder.me/) に対応しています。

## AtCoder

### Login - ログイン

First, run the `mix kyopuro.login`.

最初に`mix kyopuro.login`を実行します。

    $ mix kyopuro.login [--username USERNAME] [--password PASSWORD] [--interactive]

By default, use `Application.fetch_env` to read the login information. Write a configuration in `config.exs` and so on.

デフォルトでは`Application.fetch_env`を使用してログイン情報を読み取ります。`config.exs`にコンフィグを書くなどしてください。

```elixir
# in config/config.exs
import Config

config :kyopuro,
    username: USERNAME,
    password: PASSWORD
```

You can use the `-i` or `--interactive` option to enable the interactive login.

`-i`もしくは`--interactive`オプションを使用すれば対話形式でのログインができます。

You can use the `-u` or `--username` options to give a username as an argument.

`-u`もしくは`--username`オプションを使用すれば引数でユーザ名を与えることが可能です。

You can use the `-p` or `--password` option to give the password as an argument.

`-p`もしくは`--password`オプションを使用すれば引数でパスワードを与えることが可能です。
        
If you get a 403 error, please try again.
    
もし403エラーが出た場合は再度実行してください。
  
### Generate module & test - モジュールとテストの生成

Once you have logged in, you can specify a contest to generate modules and tests.

ログインが完了したらコンテストを指定してモジュールとテストを生成することができます。

    $ mix kyopuro.new CONTEST_NAME
    
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

### Running Tests - テストの実行

The `mix test` is used to run the test.

テストを実行するには`mix test`を使用します。

### Submit - 提出

You can submit a contest name or the name of the contest and task.

コンテスト名もしくはコンテスト名とタスク名を指定して提出することができます。

    $ mix kyopuro.submit CONTEST_NAME
    or
    $ mix kyopuro.submit CONTEST_NAME TASK_NAME

If you want to generate abc100 modules and tests, this is how it looks like.

abc100の提出をする場合は以下のようになります。

    $ mix kyopuro.submit abc100
    $ mix kyopuro.submit abc100 a

You can give multiple task names.

タスク名は複数与えることが可能です。

    $ mix kyopuro.submit abc100 a b c d

### Template - テンプレート

You can customize the templates of the generated modules.

生成するモジュールのテンプレートをカスタマイズすることができます。

```elixir
# in config/config.exs
import Config

config :kyopuro,
    module_template: "#{module_template_file_path}"
```

Only one value is currently available in the template.

テンプレートで使用できる値は現在ひとつだけです。

|name|description|
|---|---|
|module|The module name is stored in|

|名前|説明|
|---|---|
|module|モジュール名が格納されています|

Basically, extend the `priv/templates/at_coder/module.ex`

基本的には`priv/templates/at_coder/module.ex`を拡張してください

## YukiCoder

### Preparation - 準備

`config.exs`に`api_key`と`adapter`を記述してください。

```elixir
# in config/config.exs
import Config

config :kyopuro,
    api_key: API_KEY,
    adapter: Kyopuro.YukiCoder
```

### Generate module & test - モジュールとテストの生成

コンテストIDもしくは問題Noを指定してモジュールとテストを生成することができます。

    $ mix kyopuro.new [--contest CONTEST_ID] [--problem PROBLEM_NO]

ファイル構成はAtCoderと同じです。

### Running Tests - テストの実行

AtCoderと同じです。

### Submit - 提出

    $ mix kyopuro.submit [--contest CONTEST_ID] [--problem PROBLEM_ID]

### Template - テンプレート

AtCoderと同じです。

---

## Other - その他

### File name rewriting - ファイル名の書き換え

If you have rewritten the file name, edit `.mapping.json`.

モジュールファイル名を書き換えた場合は`.mapping.json`を編集してください。

The `.mapping.json` file contains the contest name, task name and file path. Since this file is referenced at the time of submission, it will not work properly if the module file name is rewritten.

`.mapping.json`はコンテスト名・タスク名とファイルパスを紐付けています。提出時にはこのファイルを参照しているので、モジュールファイル名を書き換えると正しく動作しません。

## Future - 今後の予定

- Minor update
    - 他のサイト(AOJとか)に対応する
    - 提出前にテストを実行して、失敗した場合は確認するようにする
- Patch update
    - バグ修正
    
当初の予定を実装しきった感があるのでモチベーションは低めですが、Issueとか建ててくれるとモチベーションが上がります。