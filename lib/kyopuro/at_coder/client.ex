defmodule Kyopuro.AtCoder.Client do
  @moduledoc false

  use Tesla

  adapter(Tesla.Adapter.Finch, name: Kyopuro.Finch)
  plug(Tesla.Middleware.BaseUrl, "https://atcoder.jp")
  plug(Tesla.Middleware.PathParams)
  plug(Tesla.Middleware.FormUrlencoded)

  defguard is_transport_error(error) when is_struct(error, Mint.TransportError)
  defguard is_http_error(error) when is_struct(error, Mint.HTTPError)

  @type html :: Tesla.Env.body()
  @type cookie :: String.t()

  @type client_error :: {:error, Mint.Types.error()} | {:error, {:status_code, integer()}}
  @type file_error :: {:error, {:file_read_error, File.posix()}}

  def get_task_list_page(contest_name) do
    path_params = [contest_name: contest_name]

    get("/contests/:contest_name/tasks", opts: [path_params: path_params])
    |> handle_response()
    |> case do
      {:ok, res} ->
        {:ok, res.body}

      error ->
        error
    end
  end

  def get_task_page(path) do
    case load_cookie() do
      {:ok, cookie} ->
        headers = [{"cookie", cookie}]

        get(path, headers: headers)
        |> handle_response()
        |> case do
          {:ok, res} ->
            {:ok, res.body}

          error ->
            error
        end

      {:error, reason} ->
        # :file.format_error/1 を使うといい感じのメッセージにできる
        {:error, {:file_read_error, reason}}
    end
  end

  def login(username, password) do
    case get_csrf_token() do
      {:ok, csrf_token} ->
        body = %{
          "username" => username,
          "password" => password,
          "csrf_token" => csrf_token
        }

        post("/login", body)
        |> handle_response()
        |> case do
          {:ok, res} ->
            judge_login(res.headers)

          error ->
            error
        end

      error ->
        error
    end
  end

  def submit(contest_name, task_submit_name, source_code) do
    with {:ok, csrf_token} <- get_csrf_token,
         {:ok, cookie} <- load_cookie() do
      body = %{
        "data.TaskScreenName" => task_submit_name,
        "data.LanguageId" => "4021",
        "sourceCode" => source_code,
        "csrf_token" => csrf_token
      }

      headers = [{"cookie", cookie}]

      path_params = [contest_name: contest_name]

      post("/contests/:contest_name/submit", body,
        headers: headers,
        opts: [path_params: path_params]
      )
      |> handle_response()
    else
      error ->
        error
    end
  end

  # csrf_tokenを取得
  def get_csrf_token() do
    get("/")
    |> handle_response()
    |> case do
      {:ok, res} ->
        extract_csrf_token(res.body)

      error ->
        error
    end
  end

  # リクエストのステータスコードが200,302のときはOK. それ以外はNG.

  @spec handle_response(Tesla.Env.result()) :: {:ok, Tesla.Env.t()} | {:error, Mint.Types.error()} | {:error, {:status_code, integer()}} | {:error, :something_error}
  defp handle_response({:ok, res}) when res.status in [200, 302], do: {:ok, res}
  defp handle_response({:ok, res}), do: {:error, {:status_code, res.status}}

  defp handle_response({:error, error}) when is_transport_error(error) or is_http_error(error),
    do: {:error, error}

  # cookieを読み込む
  defp load_cookie() do
    File.read(".cookie")
  end

  defp store_cookie(cookie) do
    Mix.Generator.create_file(".cookie", cookie)
  end

  # csrf_tokenを取り出す
  defp extract_csrf_token(html) do
    Floki.parse_document!(html)
    |> Floki.attribute(~s(input[name="csrf_token"]), "value")
    |> List.first()
    |> case do
      csrf_token when not is_nil(csrf_token) ->
        {:ok, csrf_token}

      nil ->
        {:error, :not_found_csrf_token}
    end
  end

  # ログイン判定. OKならsession cokkieを返す
  defp judge_login(headers) do
    headers
    |> Enum.any?(fn {key, value} ->
      key == "set-cookie" && String.starts_with?(value, "REVEL_FLASH=%00success")
    end)
    |> case do
      true ->
        headers
        |> Enum.find(fn {key, value} ->
          key == "set-cookie" && String.starts_with?(value, "REVEL_SESSION=")
        end)
        |> case do
          {"set-cookie", cookie} ->
            {:ok, cookie}

          _ ->
            {:error, :not_found_sesstion_cookie}
        end

      _ ->
        {:error, :login_failed}
    end
  end
end
