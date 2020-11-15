defmodule Kyopuro.AtCoder do
  @moduledoc false

  alias Kyopuro.Problem
  alias Kyopuro.AtCoder.Client

  @default_module_template Application.app_dir(:kyopuro, "priv/templates/at_coder/module.ex")
  @default_test_template Application.app_dir(:kyopuro, "priv/templates/at_coder/test.exs")

  def login(opts) do
    login_info =
      case Keyword.get(opts, :interactive, false) do
        true ->
          get_login_info_interactively()

        _ ->
          get_login_info_from_config()
      end

    case Client.login(login_info.username, login_info.password) do
      :ok ->
        Mix.shell().info("Login successfully.")

      :error ->
        Mix.raise("Login failed, please check your username and password.")
    end
  end

  def new(contest_name, _opts) do
    app =
      Mix.Project.config()
      |> Keyword.fetch!(:app)
      |> to_string()

    app_module = Macro.camelize(app)
    app_test = app <> "_test"
    app_test_module = app_module <> "Test"

    case Client.exists_contest?(contest_name) do
      false ->
        Mix.raise(~s(Content not found. Please check contest name "#{contest_name}"))

      true ->
        contest_path = String.downcase(contest_name)
        contest_module = String.upcase(contest_name)

        task_list_page = Client.get_contest_task_list_page(contest_name)

        task_page_list =
          extract_task_path(task_list_page)
          |> Enum.map(&Task.async(fn -> Client.get_task_page(&1) end))
          |> Enum.map(&Task.await/1)

        task_page_list
        |> Enum.zip(extract_task_name(task_list_page))
        |> Enum.map(fn {task_page, task_name} ->
          module = Module.concat([app_module, contest_module, String.upcase(task_name)])
          module_path = Path.join(["lib", app, contest_path, String.downcase(task_name) <> ".ex"])

          test_module =
            Module.concat([app_test_module, contest_module, String.upcase(task_name) <> "Test"])

          test_path =
            Path.join(["test", app_test, contest_path, String.downcase(task_name) <> "_test.exs"])

          test_cases = extract_test_cases(task_page)

          module_template =
            Application.get_env(:kyopuro, :module_template, @default_module_template)

          test_template = Application.get_env(:kyopuro, :test_template, @default_test_template)

          submit_mapping = %{
            contest_name => %{
              String.downcase(task_name) => %{
                :task_submit_name => extract_task_screen_name(task_page),
                :module_path => module_path
              }
            }
          }

          %Problem{
            module: module,
            module_path: module_path,
            test_module: test_module,
            test_path: test_path,
            test_cases: test_cases,
            module_template: module_template,
            test_template: test_template,
            submit_mapping: submit_mapping
          }
        end)
    end
  end

  def submit(contest_name, opts) do
    File.read!(".mapping.json")
    |> Jason.decode!()
    |> Map.fetch(contest_name)
    |> case do
      :error ->
        Mix.raise(
          ~s(Contest name: "#{contest_name}" mapping not found. Please check the .mapping.json.")
        )

      {:ok, contest_submit_mapping} ->
        task_name_list = Map.keys(contest_submit_mapping)

        submit(contest_name, task_name_list, opts)
    end
  end

  def submit(contest_name, task_name_list, _opts) do
    submit_mapping =
      File.read!(".mapping.json")
      |> Jason.decode!()

    case Map.fetch(submit_mapping, contest_name) do
      :error ->
        Mix.raise(
          ~s(Contest name: "#{contest_name}" mapping not found. Please check the .mapping.json.")
        )

      {:ok, contest_submit_mapping} ->
        Enum.map(task_name_list, fn task_name ->
          case Map.fetch(contest_submit_mapping, task_name) do
            :error ->
              Mix.raise(
                ~s(Task name: "#{contest_name}" mapping not found. Please check the .mapping.json.")
              )

            {:ok, task_submit_mapping} ->
              Client.submit(
                contest_name,
                Map.get(task_submit_mapping, "task_submit_name"),
                Map.get(task_submit_mapping, "module_path")
              )
          end
        end)
    end
  end

  defp get_login_info_from_config do
    with {:ok, username} <- Application.fetch_env(:kyopuro, :username),
         {:ok, password} <- Application.fetch_env(:kyopuro, :password) do
      %{username: username, password: password}
    else
      _ -> Mix.raise("Failed fetch login info. Please check config file.")
    end
  end

  defp get_login_info_interactively do
    username =
      Mix.shell().prompt("username:")
      |> String.trim()

    password =
      Mix.shell().prompt("password:")
      |> String.trim()

    %{username: username, password: password}
  end

  defp extract_task_name(html) do
    Floki.parse_document!(html)
    |> Floki.find("#main-container")
    |> Floki.find("div:nth-child(1) > div:nth-child(2) > div")
    |> Floki.find("table > tbody > tr > td:nth-child(1) > a")
    |> Enum.map(&Floki.text/1)
    |> List.flatten()
  end

  defp extract_task_path(html) do
    Floki.parse_document!(html)
    |> Floki.find("#main-container")
    |> Floki.find("div:nth-child(1) > div:nth-child(2) > div")
    |> Floki.find("table > tbody > tr > td:nth-child(1) > a")
    |> Enum.map(&Floki.attribute(&1, "href"))
    |> List.flatten()
  end

  defp extract_test_cases(html) do
    Floki.parse_document!(html)
    |> Floki.find("#main-container")
    |> Floki.find("#task-statement")
    |> Floki.find("span.lang > span.lang-ja")
    |> Floki.find("div.io-style~div.part")
    |> Floki.find("section > pre")
    |> Enum.map(&Floki.text/1)
    |> Enum.chunk_every(2)
    |> Enum.map(&Enum.zip([:input, :output], &1))
  end

  defp extract_task_screen_name(html) do
    Floki.parse_document!(html)
    |> Floki.find(~s(input[name="data.TaskScreenName"]))
    |> Floki.attribute("value")
    |> List.first()
  end

  def extract_csrf_token(html) do
    Floki.parse_document!(html)
    |> Floki.find("#main-container")
    |> Floki.find(~s(input[name="csrf_token"]))
    |> Floki.attribute("value")
    |> List.first()
  end
end
