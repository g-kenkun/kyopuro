defmodule Mix.Tasks.Kyopuro.Login do
  @moduledoc false

  use Mix.Task

  alias Kyopuro.Client

  def run(_opts) do
    #    Mix.Task.run("app.start")
    #
    #    with {:ok, username} <- Application.fetch_env(:kyopuro, :username),
    #         {:ok, password} <- Application.fetch_env(:kyopuro, :password) do
    #      Client.login(username, password)
    #    end
  end
end
