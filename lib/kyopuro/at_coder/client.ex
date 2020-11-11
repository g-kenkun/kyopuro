defmodule Kyopuro.AtCoder.Client do
  @moduledoc false

  import Meeseeks.XPath

  @type html() :: String.t()

  @base_url URI.parse("https://atcoder.jp")

  defguard is_transport_error(error) when is_struct(error, Mint.TransportError)
  defguard is_http_error(error) when is_struct(error, Mint.HTTPError)

  def get(path) do
    url = URI.merge(@base_url, path) |> URI.to_string()

    Finch.build(:get, url)
    |> Finch.request(Kyopuro.Finch)
  end

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

  @spec get_contest_task_page(path :: String.t()) :: html()
  def get_contest_task_page(path) do
    url =
      @base_url
      |> URI.merge(path)
      |> URI.to_string()

    res =
      Finch.build(:get, url)
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

      false ->
        Mix.raise(~S(Failed login. Check username and password.))
    end
  end

  def submit(contest_name, file_name) do
    build_submit_request(contest_name, file_name)
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

    cookie = extract_cookie(res.headers)

    headers = [{"content-type", "application/x-www-form-urlencoded;"}, {"cookie", cookie}]

    csrf_token = extract_csrf_token(res.body, ~s(//*[@id="main-container"]/div[1]/div/form/input))
    username = URI.encode_www_form(username)
    password = URI.encode_www_form(password)

    body = "username=#{username}&password=#{password}&csrf_token=#{csrf_token}"

    Finch.build(:post, url, headers, body)
  end

  defp build_submit_request(contest_name, file_name) do
    url =
      @base_url
      |> URI.merge("/contests/#{contest_name}/submit")
      |> URI.to_string()

    cookie = load_cookie()

    headers = [{"content-type", "application/x-www-form-urlencoded;"}, {"cookie", cookie}]

    res =
      Finch.build(:get, url, headers)
      |> Finch.request(Kyopuro.Finch)
      |> handle_response()

    app_base_path = Mix.Project.config() |> Keyword.fetch!(:app) |> to_string()

    file_name = Path.basename(file_name, ".ex") <> ".ex"

    source_code =
      Path.join(["lib", app_base_path, contest_name, file_name])
      |> File.read!()
      |> String.replace(~r/(?<=defmodule ).*?(?= do)/, "Main", global: false)
      |> URI.encode_www_form()

    csrf_token =
      extract_csrf_token(res.body, ~s(//*[@id="main-container"]//input[@name="csrf_token"]))

    body =
      "data.TaskScreenName=#{file_name}&data.LanguageId=4021&sourceCode=#{source_code}&csrf_token=#{
        csrf_token
      }"

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

  defp extract_csrf_token(body, xpath) do
    Meeseeks.parse(body)
    |> Meeseeks.one(xpath(xpath))
    |> Meeseeks.attr("value")
  end

  defp extract_cookie(headers) do
    headers
    |> Enum.filter(fn {key, _} -> key == "set-cookie" end)
    |> Enum.map(&elem(&1, 1))
    |> Enum.join("; ")
  end

  defp store_cookie(cookie) do
    Mix.Generator.create_file(".cookie", cookie)
  end

  defp load_cookie do
    case File.read(".cookie") do
      {:ok, cookie} ->
        cookie

      {:error, :enoent} ->
        Mix.raise(~s(Not found .cookie file. Please mix login before submit.))

      {:error, reason} ->
        Mix.raise(~s(Load cookie error. reason: #{reason}))
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
