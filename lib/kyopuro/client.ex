defmodule Kyopuro.Client do
  use Tesla

  adapter(Tesla.Adapter.Finch, name: Kyopuro.Finch)
end
