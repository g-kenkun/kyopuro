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
      "problem_#{Map.get(task, "No")}" => %{module_path: module_path, problem_id: Map.get(task, "ProblemId")}
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
end
