defmodule Kyopuro.AtCoder do
  @moduledoc false

  import Meeseeks.XPath

  alias Kyopuro.Problem
  alias Kyopuro.AtCoder.Client

  @default_module_template Application.app_dir(:kyopuro, "priv/templates/at_coder/module.ex")
  @default_test_template Application.app_dir(:kyopuro, "priv/templates/at_coder/test.exs")

  def new(contest_name) do
    app =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> to_string()

    app_module = Macro.camelize(app)
    app_test = app <> "_test"
    app_test_module = app_module <> "Test"

    case Client.exists_contest?(contest_name) do
      true ->
        contest_path = String.downcase(contest_name)
        contest_module = String.upcase(contest_name)

        html = Client.get_contest_task_list_page(contest_name)

        extract_task_path(html)
        |> Enum.map(&Task.async(fn -> Client.get_contest_task_page(&1) end))
        |> Enum.map(&Task.await/1)
        |> Enum.map(&extract_test_cases/1)
        |> Enum.zip(extract_task_name(html))
        |> Enum.map(fn {test_cases, task_name} ->
          module = Module.concat([app_module, contest_module, String.upcase(task_name)])
          module_path = Path.join(["lib", app, contest_path, String.downcase(task_name) <> ".ex"])

          test_module =
            Module.concat([app_test_module, contest_module, String.upcase(task_name) <> "Test"])

          test_path =
            Path.join(["test", app_test, contest_path, String.downcase(task_name) <> "_test.exs"])

          module_template =
            Application.get_env(:kyopuro, :module_template, @default_module_template)

          test_template = Application.get_env(:kyopuro, :test_template, @default_test_template)

          %Problem{
            module: module,
            module_path: module_path,
            test_module: test_module,
            test_path: test_path,
            test_cases: test_cases,
            module_template: module_template,
            test_template: test_template
          }
        end)

      false ->
        Mix.raise(~s(Content not found. Please check contest name "#{contest_name}"))
    end
  end

  defp extract_task_name(html) do
    Meeseeks.parse(html)
    |> Meeseeks.all(xpath(~S(//*[@id="main-container"]/div[1]/div[2]/div/table/tbody/tr/td[1]/a)))
    |> Enum.map(&Meeseeks.text/1)
  end

  defp extract_task_path(html) do
    Meeseeks.parse(html)
    |> Meeseeks.all(xpath(~S(//*[@id="main-container"]/div[1]/div[2]/div/table/tbody/tr/td[1]/a)))
    |> Enum.map(&Meeseeks.attr(&1, "href"))
  end

  defp extract_test_cases(html) do
    Regex.scan(~r/<pre>(?!(\r\n<var>|<var>))(.*?)<\/pre>/s, html, capture: :all_but_first)
    |> List.flatten()
    |> Enum.reject(&(&1 == ""))
    |> Enum.map(&String.trim_leading/1)
    |> Enum.uniq()
    |> Enum.map(&String.replace(&1, "\r\n", "\n"))
    |> Enum.chunk_every(2)
    |> Enum.map(&Enum.zip([:input, :output], &1))
  end
end
