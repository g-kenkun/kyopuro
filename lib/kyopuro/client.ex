defmodule Kyopuro.Client do
  @moduledoc false

  @type html() :: String.t()

  @base_url URI.parse("https://atcoder.jp")

  def login(username, password) do
    # CSRF Tokenを取得するためにログイン画面を取得
    res = HTTPoison.get!(URI.append_path(@base_url, "/login") |> URI.to_string())

    # CSRF TokenはCookieと一緒に投げる必要があるのでレスポンスヘッダーからCookie文字列を抜き出す
    cookies_string = extract_cookies(res.headers) |> serialize_cookies()

    # CSRF Tokenを抜き出す
    csrf_token = extract_csrf_token(res.body)

    # ログインリクエストを送信
    res =
      HTTPoison.post!(
        URI.append_path(@base_url, "/login") |> URI.to_string(),
        {:form,
         [
           {"username", username},
           {"password", password},
           {"csrf_token", csrf_token}
         ]},
        [{"Accept-Language", "ja-JP"}, {"Content-Type", "application/x-www-form-urlencoded"}],
        hackney: [cookie: [cookies_string]]
      )

    # set-cookieヘッダーのみを抽出
    Enum.filter(res.headers, fn {key, _} -> String.match?(key, ~r/\Aset-cookie\z/i) end)
    |> Enum.any?(fn {_, set_cookie_string} ->
      # set-cookieヘッダーに`REVEL_FLASH=%00success`で始まる文字列が含まれていればログイン成功
      String.starts_with?(set_cookie_string, "REVEL_FLASH=%00success")
    end)
    |> if do
      # Cookieは今後のリクエストで使うので、ログイン成功の場合はCookieをファイルに保存しておく
      extract_cookies(res.headers)
      |> save_cookies(URI.parse(res.request_url).host)

      :ok
    else
      :error
    end
  end

  def contests() do
    # Cookieを読み込む
    cookies_string =
      load_cookies()
      |> serialize_cookies()

    # ENHANCE: ヘッダーとクッキーは毎回セットするのでなんかいい感じに共通処理に落としたい（use HTTPoisonすればいい話だがモジュールを増やしたくない気持ちがある）
    res =
      HTTPoison.get!(
        URI.append_path(@base_url, "/contests") |> URI.to_string(),
        [{"Accept-Language", "ja-JP"}],
        hackney: [cookie: [cookies_string]]
      )

    Floki.parse_document!(res.body)
    |> Floki.find("#contest-table-permanent table tbody tr")
    |> Enum.map(fn node ->
      %{
        contest_name: Floki.find(node, "td:first-of-type a") |> Floki.text(),
        rated_target: Floki.find(node, "td:last-of-type") |> Floki.text(),
        link: Floki.find(node, "td:first-of-type a") |> Floki.attribute("href") |> List.first()
      }
    end)
  end

  def contests(query) do
    cookies_string =
      load_cookies()
      |> serialize_cookies()

    res =
      HTTPoison.get!(
        URI.append_path(@base_url, "/contests/archive") |> URI.to_string(),
        [{"Accept-Language", "ja-JP"}],
        hackney: [cookie: [cookies_string]],
        params: query
      )

    html_tree = Floki.parse_document!(res.body)

    contests =
      html_tree
      |> Floki.find("#main-container > div > div > div.panel > div > table > tbody > tr")
      |> Enum.map(fn node ->
        %{
          contest_name: Floki.find(node, "td:nth-of-type(2) a") |> Floki.text(),
          rated_target: Floki.find(node, "td:last-of-type") |> Floki.text(),
          link: Floki.find(node, "td:nth-of-type(2) a") |> Floki.attribute("href") |> List.first()
        }
      end)

    {prev, next} =
      with(
        paginations when paginations != [] <-
          Floki.find(
            html_tree,
            "#main-container > div > div > div.text-center:first-of-type > ul.pagination > li"
          ),
        index when not is_nil(index) <-
          Enum.find_index(paginations, &(Floki.attribute(&1, "class") == ["active"]))
      ) do
        {index > 0, Enum.count(paginations) > index + 1}
      else
        [] ->
          {false, false}

        nil ->
          {false, false}
      end

    %{has_prev_page: prev, has_next_page: next, contests: contests}
  end

  def rated_types() do
    cookies_string =
      load_cookies()
      |> serialize_cookies()

    res =
      HTTPoison.get!(
        URI.append_path(@base_url, "/contests") |> URI.to_string(),
        [{"Accept-Language", "ja-JP"}],
        hackney: [cookie: [cookies_string]]
      )

    Floki.parse_document!(res.body)
    |> Floki.find("#rated-type-btn-group button")
    |> Enum.map(fn node ->
      %{
        rated_type: Floki.text(node),
        data_rated_type: Floki.attribute(node, "data-rated-type") |> List.first()
      }
    end)
  end

  def categories() do
    cookies_string =
      load_cookies()
      |> serialize_cookies()

    res =
      HTTPoison.get!(
        URI.append_path(@base_url, "/contests") |> URI.to_string(),
        [{"Accept-Language", "ja-JP"}],
        hackney: [cookie: [cookies_string]]
      )

    Floki.parse_document!(res.body)
    |> Floki.find("#category-btn-group button")
    |> Enum.map(fn node ->
      %{
        category: Floki.text(node),
        data_category: Floki.attribute(node, "data-category") |> List.first()
      }
    end)
  end

  def tasks(contest) do
    cookies_string =
      load_cookies()
      |> serialize_cookies()

    res =
      HTTPoison.get!(
        @base_url
        |> URI.append_path(contest.link)
        |> URI.append_path("/tasks")
        |> URI.to_string(),
        [{"Accept-Language", "ja-JP"}],
        hackney: [cookie: [cookies_string]]
      )

    Floki.parse_document!(res.body)
    |> Floki.find("#main-container > div > div > div.panel > table > tbody > tr")
    |> Enum.map(fn node ->
      %{
        level: Floki.find(node, "td:first-of-type(2) a") |> Floki.text(),
        task_name: Floki.find(node, "td:nth-of-type(2) a") |> Floki.text(),
        link: Floki.find(node, "td:nth-of-type(2) a") |> Floki.attribute("href") |> List.first(),
        task_screen_name:
          Floki.find(node, "td:last-of-type a")
          |> Floki.attribute("href")
          |> List.first()
          |> URI.decode_query()
          |> Map.values()
          |> List.first()
      }
    end)
  end

  def test_cases(task) do
    cookies_string =
      load_cookies()
      |> serialize_cookies()

    res =
      HTTPoison.get!(
        URI.append_path(@base_url, task.link) |> URI.to_string(),
        [{"Accept-Language", "ja-JP"}],
        hackney: [cookie: [cookies_string]]
      )

    doc = Floki.parse_document!(res.body)

    case Floki.find(doc, "#task-statement > #task-statement") do
      # 古いコンテストと最近のコンテストだとテストケースのHTMLが異なるので↑のxpathで分岐させる
      [] ->
        doc
        |> Floki.find(
          "#task-statement span.lang > span.lang-ja div.io-style~div.part section > pre"
        )
        |> Enum.map(&Floki.text/1)

      _ ->
        doc
        |> Floki.find("#task-statement div.part section pre.prettyprint.linenums")
        |> Enum.map(&Floki.text/1)
        |> Enum.map(&String.replace(&1, ~r/\r\n|\n|\r/, "", global: false))
    end
    |> Enum.map(&String.replace(&1, ~r/\r\n|\r/, "\n"))
    |> Enum.chunk_every(2)
    |> Enum.map(&Enum.zip([:input, :output], &1))
  end

  def submit(contest_name, task_screen_name, source_code) do
    cookies_string =
      load_cookies()
      |> serialize_cookies()

    res =
      HTTPoison.get!(
        @base_url
        |> URI.append_path("/contests")
        |> URI.append_path("/" <> contest_name)
        |> URI.append_path("/submit")
        |> URI.to_string(),
        [{"Accept-Language", "ja-JP"}],
        hackney: [cookie: [cookies_string]]
      )

    cookies = extract_cookies(res.headers)

    save_cookies(cookies, URI.parse(res.request_url).host)

    cookies_string = serialize_cookies(cookies)

    HTTPoison.post!(
      @base_url
      |> URI.append_path("/contests")
      |> URI.append_path("/" <> contest_name)
      |> URI.append_path("/submit")
      |> URI.to_string(),
      {:form,
       [
         {"data.TaskScreenName", task_screen_name},
         {"data.LanguageId", "5085"},
         {"sourceCode", source_code},
         {"csrf_token", extract_csrf_token(res.body)}
       ]},
      [{"Accept-Language", "ja-JP"}, {"content-type", "application/x-www-form-urlencoded"}],
      hackney: [cookie: [cookies_string]]
    )
  end

  def extract_csrf_token(html) do
    Floki.parse_document!(html)
    |> Floki.find(~s(input[name="csrf_token"]))
    |> Floki.attribute("value")
    |> List.first()
  end

  defp extract_cookies(headers) do
    Enum.filter(headers, fn {key, _} -> String.match?(key, ~r/\Aset-cookie\z/i) end)
    |> Enum.map(fn {_, set_cookie_string} ->
      [{cookie_name, cookie_value} | cookie_avs] = :hackney_cookie.parse_cookie(set_cookie_string)

      Enum.map(cookie_avs, fn {cookie_av_key, cookie_av_value} ->
        case cookie_av_key do
          "Expires" ->
            {:expires, cookie_av_value}

          "Max-Age" ->
            {:max_age, cookie_av_value}

          "Domain" ->
            {:domain, cookie_av_value}

          "Path" ->
            {:path, cookie_av_value}

          "Secure" ->
            {:secure, true}

          "HttpOnly" ->
            {:http_only, true}
        end
      end)
      |> Enum.concat([{:name, cookie_name}, {:value, cookie_value}])
      |> Map.new()
    end)
  end

  defp save_cookies(cookies, host) do
    cookie_jar =
      Enum.map(cookies, fn cookie ->
        domain_name = if Map.get(cookie, :http_only), do: "#HttpOnly_" <> host, else: host
        include_subdomains = if Map.get(cookie, :domain), do: "TRUE", else: "FALSE"
        path = Map.get(cookie, :path, "")
        secure = if Map.get(cookie, :secure), do: "TRUE", else: "FALSE"

        expires_at =
          cond do
            # Timexでパースしたい気持ちもある
            Map.get(cookie, :max_age) != nil ->
              DateTime.utc_now()
              |> DateTime.add(Map.get(cookie, :max_age) |> String.to_integer())
              |> DateTime.to_unix()

            Map.get(cookie, :expires) != nil ->
              Map.get(cookie, :expires)
              |> :hackney_date.parse_http_date()
              |> NaiveDateTime.from_erl!()
              |> DateTime.from_naive!("Etc/UTC")
              |> DateTime.to_unix()

            true ->
              0
          end

        [
          domain_name,
          include_subdomains,
          path,
          secure,
          expires_at,
          cookie.name,
          cookie.value
        ]
        |> Enum.join("\t")
      end)
      |> Enum.join("\n")

    Mix.Generator.create_file("cookie", cookie_jar, quite: true, force: true)
  end

  defp load_cookies() do
    case File.read("cookie") do
      {:ok, cookie_jar} ->
        # TODO: Mapに変換するところから
        cookie_jar
        |> String.split("\n")
        |> Enum.reject(fn line ->
          String.starts_with?(line, "#") && !String.starts_with?(line, "#HttpOnly_")
        end)
        |> Enum.map(&String.split(&1, "\t"))
        |> Enum.filter(&(Kernel.length(&1) == 7))
        |> Enum.map(fn [_domain_name, include_subdomains, path, secure, expires_at, name, value] ->
          %{
            domain: include_subdomains,
            path: path,
            secure: secure,
            expires_at: expires_at,
            name: name,
            value: value
          }
        end)

      {:error, :enoent} ->
        Mix.raise(~s(mix kyopuro.login を実行してください))

      {:error, reason} ->
        Mix.raise(~s(Cookieのロードに失敗しました。 理由:#{:file.format_error(reason)}))
    end
  end

  defp serialize_cookies(cookies) do
    Enum.map(cookies, fn cookie ->
      cookie.name <> "=" <> cookie.value
    end)
    |> Enum.join("; ")
  end
end
