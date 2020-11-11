defmodule <%= inspect(test_module) %> do
  use ExUnit.Case

  import ExUnit.CaptureIO
<%= for test_case <- test_cases do %>
  test <%= inspect(Keyword.get(test_case, :input)) %> do
    assert(
      capture_io([input: <%= inspect(Keyword.get(test_case, :input)) %>, capture_prompt: false], fn ->
          <%= inspect(module) %>.main()
      end) == <%= inspect(Keyword.get(test_case, :output)) %>
    )
  end
<% end %>
end