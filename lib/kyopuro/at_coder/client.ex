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

  def submit(contest_name, task_submit_name, file_name) do
    build_submit_request(contest_name, task_submit_name, file_name)
    |> Finch.request(Kyopuro.Finch)
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

  defp build_submit_request(contest_name, task_submit_name, module_path) do
    url =
      @base_url
      |> URI.merge("/contests/#{contest_name}/submit")
      |> URI.to_string()

    headers = [{"content-type", "application/x-www-form-urlencoded;"}, {"cookie", load_cookie()}]

    res =
      Finch.build(:get, url, headers)
      |> Finch.request(Kyopuro.Finch)
      |> handle_response()

    source_code =
      case File.read(module_path) do
        {:error, :enoent} ->
          Mix.raise(~s(The file "#{module_path}" was not found.))

        {:error, reason} ->
          Mix.raise(~s(An error occurred while opening the file. Reason: "#{reason}"))

        {:ok, source_code} ->
          String.replace(source_code, ~r/(?<=defmodule ).*?(?= do)/, "Main", global: false)
      end

    body =
      URI.encode_query(%{
        "data.TaskScreenName" => task_submit_name,
        "data.LanguageId" => "4021",
        "sourceCode" => source_code,
        "csrf_token" => extract_csrf_token(res.body)
      })

    Finch.build(:post, url, headers, body)
  end

  defp handle_response({:error, error}) when is_transport_error(error),
    do: Mix.raise(~s(Transport error. Please check network.))

  defp handle_response({:error, error}) when is_http_error(error),
    do: Mix.raise(~s(HTTP error. Please check network.))

  defp handle_response({:ok, res}) when res.status == 404, do: Mix.raise(~s(Not found page.))
  defp handle_response({:ok, res}) when res.status == 200, do: res
  defp handle_response({:ok, res}) when res.status == 302, do: res
  defp handle_response({:ok, res}), do: Mix.raise(~s(Error. status_code: #{res.status}))

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
