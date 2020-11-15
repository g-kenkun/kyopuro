defmodule Kyopuro.Problem do
  @moduledoc false

  defstruct module: nil,
            module_path: nil,
            test_module: nil,
            test_path: nil,
            test_cases: [],
            module_template: nil,
            test_template: nil,
            submit_mapping: %{},
            binding: []
end
