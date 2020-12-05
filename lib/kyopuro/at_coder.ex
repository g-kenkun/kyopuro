defmodule Kyopuro.AtCoder do
  @moduledoc false

  alias Kyopuro.Problem
  alias Kyopuro.AtCoder.Client

  @default_module_template Application.app_dir(:kyopuro, "priv/templates/at_coder/module.ex")
  @default_test_template Application.app_dir(:kyopuro, "priv/templates/at_coder/test.exs")

  def login(_args, opts) do
    login_info = get_login_info(opts)

    case Client.login(login_info.username, login_info.password) do
      :ok ->
        Mix.shell().info("Login successfully.")

      :error ->
        Mix.raise("Login failed, please check username and password.")
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
                task_submit_name: extract_task_screen_name(task_page),
                module_path: module_path
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

  def submit(args, _opts) do
    [contest_name | task_name_list] = args

    mapping =
      File.read!(".mapping.json")
      |> Jason.decode!()

    contest_mapping =
      mapping
      |> get_contest_mapping(contest_name)

    task_mapping =
      case task_name_list do
        [] ->
          Map.values(contest_mapping)

        _ ->
          Enum.map(task_name_list, &get_task_mapping(contest_mapping, &1))
      end

    Enum.map(task_mapping, &request_submit(contest_name, &1))
  end

  defp get_login_info(opts) do
    username = get_login_info(:username, opts)
    password = get_login_info(:password, opts)

    %{username: username, password: password}
  end

  defp get_login_info(key, opts) do
    case Application.fetch_env(:kyopuro, key) do
      {:ok, username} ->
        username

      :error ->
        cond do
          opts[key] ->
            opts[key]

          opts[:interactive] ->
            Mix.shell().prompt("#{key}:")
            |> String.trim()

          true ->
            Mix.raise("Failed fetch login info.")
        end
    end
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
    |> Enum.map(&String.replace(&1, "\r\n", "\n"))
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

  defp get_contest_mapping(mapping, contest_name) do
    case Map.fetch(mapping, contest_name) do
      :error ->
        Mix.raise(
          ~s(Contest name: "#{contest_name}" mapping not found. Please check the .mapping.json.")
        )

      {:ok, contest_mapping} ->
        contest_mapping
    end
  end

  defp get_task_mapping(mapping, problem_name) do
    case Map.fetch(mapping, problem_name) do
      :error ->
        Mix.raise(
          ~s(Problem name: "#{problem_name}" mapping not found. Please check the .mapping.json.")
        )

      {:ok, task_mapping} ->
        task_mapping
    end
  end

  defp request_submit(contest_name, task_mapping) do
    task_submit_name = Map.fetch!(task_mapping, "task_submit_name")

    source_code =
      case File.read(Map.get(task_mapping, "module_path")) do
        {:error, :enoent} ->
          Mix.raise(~s(The file "#{Map.get(task_mapping, "module_path")}" was not found.))

        {:error, reason} ->
          Mix.raise(~s(An error occurred while opening the file. Reason: "#{reason}"))

        {:ok, source_code} ->
          String.replace(source_code, ~r/(?<=defmodule ).*?(?= do)/, "Main", global: false)
      end

    Client.submit(contest_name, task_submit_name, source_code)
  end
end
