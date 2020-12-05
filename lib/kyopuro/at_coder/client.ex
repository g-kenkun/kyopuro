defmodule Kyopuro.AtCoder.Client do
  @moduledoc false

  @type html() :: String.t()

  @base_url URI.parse("https://atcoder.jp")

  defguard is_transport_error(error) when is_struct(error, Mint.TransportError)
  defguard is_http_error(error) when is_struct(error, Mint.HTTPError)

  @spec exists_contest?(contest_name :: String.t()) :: true | false
  def exists_contest?(contest_name) do
    url =
      @base_url
      |> URI.merge("/contests/#{contest_name}")
      |> URI.to_string()

    Finch.build(:get, url)
    |> Finch.request(Kyopuro.Finch)
    |> case do
      {:ok, %Finch.Response{status: 200}} ->
        true

      _ ->
        false
    end
  end

  @spec get_contest_task_list_page(contest_name :: String.t()) :: html()
  def get_contest_task_list_page(contest_name) do
    url =
      @base_url
      |> URI.merge("/contests/#{contest_name}/tasks")
      |> URI.to_string()

    res =
      Finch.build(:get, url)
      |> Finch.request(Kyopuro.Finch)
      |> handle_response()

    res.body
  end

  @spec get_task_page(path :: String.t()) :: html()
  def get_task_page(path) do
    url =
      @base_url
      |> URI.merge(path)
      |> URI.to_string()

    res =
      Finch.build(:get, url, [{"cookie", load_cookie()}])
      |> Finch.request(Kyopuro.Finch)
      |> handle_response()

    res.body
  end

  def login(username, password) do
    res =
      build_login_request(username, password)
      |> Finch.request(Kyopuro.Finch)
      |> handle_response()

    case judge_login_response(res.headers) do
      true ->
        extract_cookie(res.headers)
        |> store_cookie()

        :ok

      false ->
        :error
    end
  end

  def submit(contest_name, task_submit_name, source_code) do
    path = "/contests/#{contest_name}/submit"
    res =
      build_get_request(path)
      |> add_cookie_header()
      |> request()

    body =
      URI.encode_query(%{
        "data.TaskScreenName" => task_submit_name,
        "data.LanguageId" => "4021",
        "sourceCode" => source_code,
        "csrf_token" => extract_csrf_token(res.body)
      })

    build_post_request(path, [], body)
    |> add_cookie_header()
    |> add_content_type_header()
    |> request()
  end

  defp build_login_request(username, password) do
    url =
      @base_url
      |> URI.merge("/login")
      |> URI.to_string()

    res =
      Finch.build(:get, url)
      |> Finch.request(Kyopuro.Finch)
      |> handle_response()

    headers = [
      {"content-type", "application/x-www-form-urlencoded"},
      {"cookie", extract_cookie(res.headers)}
    ]

    body =
      URI.encode_query(%{
        "username" => username,
        "password" => password,
        "csrf_token" => extract_csrf_token(res.body)
      })

    Finch.build(:post, url, headers, body)
  end

  def build_get_request(path, headers \\ []),
      do: build_request(:get, path, headers, "")

  def build_post_request(path, headers \\ [], body \\ ""),
      do: build_request(:post, path, headers , body)

  def build_request(method, path, headers, body) do
    uri =
      @base_url
      |> URI.merge(path)
      |> URI.to_string()

    Finch.build(method, uri, headers, body)
  end

  def request(request) do
    Finch.request(request, Kyopuro.Finch)
    |> handle_response()
  end

  defp add_cookie_header(request, cookie \\ load_cookie()) do
    cookie_header = [{"cookie", cookie}]
    %{request | headers: request.headers ++ cookie_header}
  end

  defp add_content_type_header(request) do
    content_type_header = [{"content-type", "application/x-www-form-urlencoded"}]
    %{request | headers: request.headers ++ content_type_header}
  end

  defp handle_response({:ok, res}) when res.status == 200, do: res
  defp handle_response({:ok, res}) when res.status == 302, do: res
  defp handle_response({:ok, res}) when res.status == 404, do: Mix.raise(~s(Not found page.))
  defp handle_response({:ok, res}), do: Mix.raise(~s(Error. status_code: #{res.status}))

  defp handle_response({:error, error}) when is_transport_error(error),
    do: Mix.raise(~s(Transport error. Please check network.))

  defp handle_response({:error, error}) when is_http_error(error),
    do: Mix.raise(~s(HTTP error. Please check network.))





  def extract_csrf_token(html) do
    Floki.parse_document!(html)
    |> Floki.find("#main-container")
    |> Floki.find(~s(input[name="csrf_token"]))
    |> Floki.attribute("value")
    |> List.first()
  end

  defp extract_cookie(headers) do
    headers
    |> Enum.flat_map(fn {key, value} ->
      case String.match?(key, ~r/set-cookie/) do
        true -> String.split(value, ";", trim: true)
        _ -> []
      end
    end)
    |> Enum.filter(&String.starts_with?(&1, "REVEL_SESSION="))
    |> List.first()
  end

  defp store_cookie(cookie) do
    Mix.Generator.create_file(".cookie", cookie)
  end

  defp load_cookie do
    case File.read(".cookie") do
      {:ok, cookie} ->
        cookie

      {:error, :enoent} ->
        Mix.raise(~s(Please run mix kyopuro.login))

      {:error, reason} ->
        Mix.raise(~s(There was an error loading the .cookie file. reason: #{reason}))
    end
  end

  defp judge_login_response(headers) do
    headers
    |> Enum.filter(fn {key, value} ->
      key == "set-cookie" && String.starts_with?(value, "REVEL_FLASH=%00success")
    end)
    |> Enum.empty?()
    |> Kernel.!()
  end
end
