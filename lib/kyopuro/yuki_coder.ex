defmodule Kyopuro.YukiCoder do
  @moduledoc false

  alias Kyopuro.Problem
  alias Kyopuro.YukiCoder.Client

  @default_module_template Application.app_dir(:kyopuro, "priv/templates/yuki_coder/module.ex")
  @default_test_template Application.app_dir(:kyopuro, "priv/templates/yuki_coder/test.exs")

  def new(args, opts) do
    case opts[:contest] do
      true ->
        [contest_id | _] = args
        generate_problem_by_contest_id(contest_id)

      _ ->
        [problem_no | _] = args
        [generate_problem_by_problem_no(problem_no)]
    end
  end

  def submit(args, opts) do
    contest_id = Keyword.get(opts, :contest)
    problem_no = Keyword.get(opts, :problem)

    mapping =
      File.read!(".mapping.json")
      |> Jason.decode!()

    cond do
      contest_id ->
        get_contest_mapping(mapping, contest_id)
        |> Enum.map(&request_submit/1)

      problem_no ->
        get_problem_mapping(mapping, problem_no)
        |> request_submit()

      true ->
        Mix.Tasks.Help.run(["kyopuro.submit"])
    end
  end

  defp generate_problem_by_problem_no(problem_no) do
    Client.get_problem_by_no(problem_no)
    |> Map.get("ProblemId")
    |> generate_problem_by_problem_id()
  end

  defp generate_problem_by_problem_id(problem_id) do
    problem = Problem.new()

    task = Client.get_problem_by_id(problem_id)

    test_cases =
      task
      |> Map.get("ProblemId")
      |> Client.get_problem_test_cases()

    module = Module.concat([problem.app_module, "Problem#{Map.get(task, "No")}"])

    module_path =
      Path.join([
        "lib",
        problem.app,
        "problem_#{Map.get(task, "No")}" <> ".ex"
      ])

    test_module =
      Module.concat([problem.app_test_module, "Problem#{Map.get(task, "No")}" <> "Test"])

    test_path =
      Path.join([
        "test",
        problem.app_test,
        "problem_#{Map.get(task, "No")}" <> "_test.exs"
      ])

    module_template = Application.get_env(:kyopuro, :module_template, @default_module_template)

    test_template = Application.get_env(:kyopuro, :test_template, @default_test_template)

    submit_mapping = %{
      "problem_#{Map.get(task, "No")}" => %{
        module_path: module_path,
        problem_id: Map.get(task, "ProblemId")
      }
    }

    %{
      problem
      | module: module,
        module_path: module_path,
        test_module: test_module,
        test_path: test_path,
        test_cases: test_cases,
        module_template: module_template,
        test_template: test_template,
        submit_mapping: submit_mapping
    }
  end

  defp generate_problem_by_contest_id(contest_id) do
    contest = Client.get_contest(contest_id)

    contest
    |> Map.get("ProblemIdList")
    |> Enum.map(&generate_problem_by_problem_id/1)
    |> Enum.map(fn problem ->
      module =
        problem.module
        |> Module.split()
        |> List.insert_at(1, "contest_#{Map.get(contest, "Id")}")
        |> Module.concat()

      module_path =
        problem.module_path
        |> Path.split()
        |> List.insert_at(2, "contest_#{Map.get(contest, "Id")}")

      test_module =
        problem.test_module
        |> Module.split()
        |> List.insert_at(1, "contest_#{Map.get(contest, "Id")}")
        |> Module.concat()

      test_path =
        problem.test_path
        |> Path.split()
        |> List.insert_at(2, "contest_#{Map.get(contest, "Id")}")

      submit_mapping = %{
        "Contest#{Map.get(contest, "Id")}" => module.submit_mapping
      }

      %{
        problem
        | module: module,
          module_path: module_path,
          test_module: test_module,
          test_path: test_path,
          submit_mapping: submit_mapping
      }
    end)
  end

  defp get_contest_mapping(mapping, contest_id) do
    case Map.fetch(mapping, contest_id) do
      :error ->
        Mix.raise(
          ~s(Contest ID: "#{contest_id}" not found on mapping. Please check the .mapping.json.")
        )

      {:ok, contest_mapping} ->
        contest_mapping
    end
  end

  defp get_problem_mapping(mapping, problem_no) do
    case Map.fetch(mapping, "problem_#{problem_no}") do
      :error ->
        Mix.raise(
          ~s(Problem No: "#{problem_no}" not found on mapping. Please check the .mapping.json.")
        )

      {:ok, problem_mapping} ->
        problem_mapping
    end
  end

  defp request_submit(problem_mapping) do
    problem_id = Map.get(problem_mapping, :problem_id)

    source_code =
      case File.read(Map.get(problem_mapping, "module_path")) do
        {:error, :enoent} ->
          Mix.raise(~s(The file "#{Map.get(problem_mapping, "module_path")}" was not found.))

        {:error, reason} ->
          Mix.raise(~s(An error occurred while opening the file. Reason: "#{reason}"))

        {:ok, source_code} ->
          String.replace(source_code, ~r/(?<=defmodule ).*?(?= do)/, "Main", global: false)
      end

    body = URI.encode_query(%{"lang" => "elixir", "source" => source_code})

    Client.submit_problem(problem_id, body)
  end
end
