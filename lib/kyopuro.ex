defmodule Kyopuro do
  @moduledoc false

  alias Kyopuro.Problem

  def generate(problem) do
    generate_module(problem)
    generate_test(problem)
  end

  def put_binding(problem) do
    binding = [
      module: problem.module,
      test_module: problem.test_module,
      test_cases: problem.test_cases
    ]

    %Problem{problem | binding: binding}
  end

  defp generate_module(problem) do
    contents =
      EEx.eval_string(File.read!(problem.module_template), problem.binding,
        file: problem.module_template
      )

    Mix.Generator.create_file(problem.module_path, contents)
  end

  defp generate_test(problem) do
    contents =
      EEx.eval_string(File.read!(problem.test_template), problem.binding,
        file: problem.test_template
      )

    Mix.Generator.create_file(problem.test_path, contents)
  end
end
