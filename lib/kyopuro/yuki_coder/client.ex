defmodule Kyopuro.YukiCoder.Client do
  @moduledoc false

  alias Kyopuro.YukiCoder.Client

  @base_url URI.parse("https://yukicoder.me")

  defguard is_transport_error(error) when is_struct(error, Mint.TransportError)
  defguard is_http_error(error) when is_struct(error, Mint.HTTPError)

  def get_problem_by_no(problem_no) do
    get_request("/problems/no/#{problem_no}")
    |> Jason.decode!()
  end

  def get_problem_by_id(problem_id) do
    get_request("/problems/#{problem_id}")
    |> Jason.decode!()
  end

  def get_contest(contest_id) do
    get_request("/contest/id/#{contest_id}")
    |> Jason.decode!()
  end

  def submit_problem(problem_id, source_code) do
    body = """
    --boundary
    Content-Disposition: form-data; name="lang"

    elixir
    --boundary
    Content-Disposition: form-data; name="source"

    #{source_code}
    --boundary--
    """

    post_request("/problems/#{problem_id}/submit", [{"Content-Type", ~s(multipart/form-data; boundary="boundary")}], body)
  end

  def get_problem_test_cases(problem_id) do
    in_files =
      get_problem_test_cases(problem_id, :in)
      |> Jason.decode!()
      |> Enum.sort()
      |> Enum.map(&Task.async(fn -> Client.get_problem_test_case(problem_id, :in, &1) end))
      |> Enum.map(&Task.await(&1, :infinity))
      |> Enum.to_list()

    out_files =
      get_problem_test_cases(problem_id, :out)
      |> Jason.decode!()
      |> Enum.sort()
      |> Enum.map(&Task.async(fn -> Client.get_problem_test_case(problem_id, :out, &1) end))
      |> Enum.map(&Task.await(&1, :infinity))
      |> Enum.to_list()

    Enum.zip(in_files, out_files)
    |> Enum.map(fn {in_file, out_file} -> [input: in_file, output: out_file] end)
  end

  defp get_problem_test_cases(problem_id, which) do
    get_request("/problems/#{problem_id}/file/#{which}")
  end

  def get_problem_test_case(problem_id, which, file_name) do
    get_request("/problems/#{problem_id}/file/#{which}/#{file_name}")
  end

  def get_request(path, headers \\ []) do
    uri =
      @base_url
      |> URI.merge("/api/v1" <> path)
      |> URI.to_string()

    Finch.build(:get, uri, headers)
    |> add_accept_header()
    |> add_auth_header()
    |> request()
  end

  def post_request(path, headers \\ [], body \\ "") do
    uri =
      @base_url
      |> URI.merge("/api/v1" <> path)
      |> URI.to_string()

    Finch.build(:post, uri, headers, body)
    |> add_accept_header()
    |> add_auth_header()
    |> request()
  end

  defp add_accept_header(request) do
    accept_header = [{"accept", "application/json"}]
    %{request | headers: request.headers ++ accept_header}
  end

  defp add_auth_header(request) do
    auth_header = [{"Authorization", "Bearer #{Application.fetch_env!(:kyopuro, :api_key)}"}]
    %{request | headers: request.headers ++ auth_header}
  end

  defp request(request) do
    request
    |> Finch.request(Kyopuro.Finch)
    |> handle_response()
  end

  defp handle_response({:ok, res}) when res.status == 200, do: res.body
  defp handle_response({:ok, res}) when res.status == 404, do: Mix.raise(~s(Not found page.))

  defp handle_response({:error, error}) when is_transport_error(error),
    do: Mix.raise(~s(Transport error. Please check network.))

  defp handle_response({:error, error}) when is_http_error(error),
    do: Mix.raise(~s(HTTP error. Please check network.))
end
