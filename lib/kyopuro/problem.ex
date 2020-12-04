defmodule Kyopuro.Problem do
  @moduledoc false

  alias Kyopuro.Problem

  defstruct app: nil,
            app_module: nil,
            app_test: nil,
            app_test_module: nil,
            module: nil,
            module_path: nil,
            test_module: nil,
            test_path: nil,
            test_cases: [],
            module_template: nil,
            test_template: nil,
            submit_mapping: %{},
            binding: []

  def new() do
    app =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> to_string()

    app_module = Inflex.camelize(app)
    app_test = app <> "_test"
    app_test_module = app_module <> "Test"

    %Problem{
      app: app,
      app_module: app_module,
      app_test: app_test,
      app_test_module: app_test_module
    }
  end
end
