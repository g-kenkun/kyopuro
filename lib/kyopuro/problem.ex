defmodule Kyopuro.Problem do
  @moduledoc false

  defstruct app: nil,
            app_module: nil,
            app_test: nil,
            app_test_module: nil,
            module_template: nil,
            test_template: nil,
            contest_path: nil,
            tasks: []

  def new() do
    app =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> to_string()

    app_module = Macro.camelize(app)
    app_test = app <> "_test"
    app_test_module = app_module <> "Test"

    module_template =
      case Application.fetch_env(:kyopuro, :module_template) do
        {:ok, module_template} ->
          unless File.exists?(module_template),
            do: Mix.raise("#{module_template}が存在しません。設定を見直してください。")

          module_template

        :error ->
          Application.app_dir(:kyopuro, "priv/templates/at_coder/module_template.eex")
      end

    test_template =
      case Application.fetch_env(:kyopuro, :test_template) do
        {:ok, test_template} ->
          unless File.exists?(test_template),
            do: Mix.raise("#{test_template}が存在しません。設定を見直してください。")

          test_template

        :error ->
          Application.app_dir(:kyopuro, "priv/templates/at_coder/test_template.eex")
      end

    %__MODULE__{
      app: app,
      app_module: app_module,
      app_test: app_test,
      app_test_module: app_test_module,
      module_template: module_template,
      test_template: test_template
    }
  end
end
