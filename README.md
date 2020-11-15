# Kyopuro

This package provides a mix of tasks for AtCoder. This package provides mix tasks for module generation and test case generation.

AtCoder用のmixタスクを提供するパッケージです。このパッケージはモジュールの生成とテストケースの生成、提出を行うmixタスクを提供します。

## Installation

The Meeseeks package used in this package uses Rust for Nifs, so you need to set up the Rust environment beforehand.

このパッケージで使用しているhtml5everパッケージはNifsにRustを使用しているので、予めRustの環境を構築する必要があります。

```elixir
def deps do
  [
    {:kyopuro, "~> 0.3.0"}
  ]
end
```

## Usage

### Login - ログイン

First, run the `mix kyopuro.login`.

最初に`mix kyopuro.login`を実行します。

    $ mix kyopuro.login
    
By default, it reads the login information from the configuration file.

デフォルトではコンフィグファイルからログイン情報を読み取ります。

```elixir
# in config/config.exs

config :kyopuro,
    username: "#{username}",
    password: "#{password}"
```

You can use the `--i` or `--interactive` option to enable interactive login.

`-i`もしくは`--interactive`オプションを使用すれば対話形式でのログインができます。

    $ mix kyopuro.login -i
    or
    $ mix kyopuro.login --interactive
        
If you get a 403 error, please try again.
    
もし403エラーが出た場合は再度実行してください。
  
### Generate module & test - モジュールとテストの生成

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

### Running Tests - テストの実行

The `mix test` is used to run the test.

テストを実行するには`mix test`を使用します。

### Submit - 提出

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

### Template - テンプレート

You can customize the templates of the generated modules.

生成するモジュールのテンプレートをカスタマイズすることができます。

```elixir
# in config/config.exs

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

## Other - その他

### File name rewriting - ファイル名の書き換え

If you have rewritten the file name, edit `.mapping.json`.

モジュールファイル名を書き換えた場合は`.mapping.json`を編集してください。

The `.mapping.json` file contains the contest name, task name and file path. Since this file is referenced at the time of submission, it will not work properly if the module file name is rewritten.

`.mapping.json`はコンテスト名・タスク名とファイルパスを紐付けています。提出時にはこのファイルを参照しているので、モジュールファイル名を書き換えると正しく動作しません。

## Feature

- Major update
    - 他のサイト(AOJとか)に対応するに当たって、プラグイン形式でモジュールを差し替えられるようにする
- Minor update
    - 提出前にテストを実行して、失敗した場合は確認するようにする
    - バグ修正とか
    
当初の予定を実装しきった感があるのでモチベーションは低めですが、Issueとか建ててくれるとモチベーションが上がります。