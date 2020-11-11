# Kyopuro

This package provides a mix of tasks for AtCoder. This package provides mix tasks for module generation and test case generation.

AtCoder用のmixタスクを提供するパッケージです。このパッケージはモジュールの生成とテストケースの生成を行うmixタスクを提供します。

## Installation

The Meeseeks package used in this package uses Rust for Nifs, so you need to set up the Rust environment beforehand.

このパッケージで使用しているMeeseeksパッケージはNifsにRustを使用しているので、予めRustの環境を構築する必要があります。

```elixir
def deps do
  [
    {:kyopuro, "~> 0.1.0"}
  ]
end
```

## Usage

Mix task to generate modules and test cases from a contest

コンテストからモジュールとテストケースを生成するmixタスク

    $ mix kyopuro.new [contest_name]
    $ mix kyopuro.new abc001

## Future

- [] モジュールのテンプレートを差し替えられうようにする。
- [] ファイル名とモジュール名が違っているのでなんとかする。