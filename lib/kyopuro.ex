defmodule Kyopuro do
  @moduledoc false

  alias Kyopuro.Client

  def login() do
    %{username: username, password: password} = get_login_info()

    case Client.login(username, password) do
      :ok ->
        Mix.Shell.IO.info("ログインに成功しました。")

      :error ->
        Mix.raise("ログインに失敗しました。認証情報を確認してください。")
    end
  end

  def new() do
    problem =
      [
        "URLを入力",
        "常設中のコンテスト",
        "Rated対象から検索",
        "カテゴリから検索",
        "キーワードから検索"
      ]
      |> Owl.IO.select()
      |> case do
        "URLを入力" ->
          input_uri = Owl.IO.input(label: "コンテストもしくは問題のURL")

          case URI.new(input_uri) do
            {:ok, %URI{host: "atcoder.jp"} = uri} ->
              case uri.path |> Path.split() do
                ["/", "contests", _contest_name] ->
                  contest = %{link: uri.path}

                  tasks =
                    Kyopuro.Client.tasks(contest)
                    |> select_task()
                    |> case do
                      tasks when is_list(tasks) ->
                        tasks

                      task ->
                        [task]
                    end

                  build_problem(contest, tasks)

                ["/", "contests", contest_name, _] ->
                  contest = %{link: Path.join(["/", "contests", contest_name])}

                  tasks =
                    Kyopuro.Client.tasks(contest)
                    |> select_task()
                    |> case do
                      tasks when is_list(tasks) ->
                        tasks

                      task ->
                        [task]
                    end

                  build_problem(contest, tasks)

                ["/", "contests", contest_name, "tasks", _task_name] ->
                  contest = %{link: Path.join(["/", "contests", contest_name])}

                  Kyopuro.Client.tasks(contest)
                  |> Enum.find(fn task ->
                    task.link == uri.path
                  end)
                  |> case do
                    nil ->
                      Mix.raise("問題が見つかりませんでした。")

                    task ->
                      build_problem(contest, [task])
                  end

                _ ->
                  Mix.raise("コンテストもしくは問題のURLを入力してください。")
              end

            {:ok, _} ->
              Mix.raise("コンテストもしくは問題のURLを入力してください。")

            {:error, _} ->
              Mix.raise("URLとして正しい値を入力してください。")
          end

        "常設中のコンテスト" ->
          options = Client.contests()

          contest_name_max_width =
            Enum.reduce(options, 0, fn option, max ->
              max(count_width(option.contest_name), max)
            end)

          rated_target_max_length =
            Enum.reduce(options, 0, fn option, max ->
              max(count_width(option.rated_target), max)
            end)

          contest =
            options
            |> Owl.IO.select(
              render_as: fn option ->
                "#{pad_trailing_for_console(option.contest_name, contest_name_max_width)} | #{pad_trailing_for_console(option.rated_target, rated_target_max_length)}"
              end
            )

          tasks =
            Kyopuro.Client.tasks(contest)
            |> select_task()
            |> case do
              tasks when is_list(tasks) ->
                tasks

              task ->
                [task]
            end

          build_problem(contest, tasks)

        "Rated対象から検索" ->
          selected =
            Client.rated_types()
            |> Owl.IO.select(
              render_as: fn option ->
                option.rated_type
              end
            )

          contest = select_contest(%{"ratedType" => selected.data_rated_type})

          tasks =
            Kyopuro.Client.tasks(contest)
            |> select_task()
            |> case do
              tasks when is_list(tasks) ->
                tasks

              task ->
                [task]
            end

          build_problem(contest, tasks)

        "カテゴリから検索" ->
          selected =
            Client.categories()
            |> Owl.IO.select(
              render_as: fn option ->
                option.category
              end
            )

          contest = select_contest(%{"category" => selected.data_category})

          tasks =
            Kyopuro.Client.tasks(contest)
            |> select_task()
            |> case do
              tasks when is_list(tasks) ->
                tasks

              task ->
                [task]
            end

          build_problem(contest, tasks)

        "キーワードから検索" ->
          search_keyword =
            Owl.IO.input(label: "キーワード")
            |> String.split()
            |> Enum.join("+")

          contest = select_contest(%{"keyword" => search_keyword})

          tasks =
            Kyopuro.Client.tasks(contest)
            |> select_task()
            |> case do
              tasks when is_list(tasks) ->
                tasks

              task ->
                [task]
            end

          build_problem(contest, tasks)
      end

    Enum.each(
      problem.tasks,
      fn task ->
        contents =
          EEx.eval_file(
            problem.module_template,
            module: task.module
          )

        Mix.Generator.create_file(task.module_path, contents)

        contents =
          EEx.eval_file(
            problem.test_template,
            module: task.module,
            test_module: task.test_module,
            test_cases: task.test_cases
          )

        Mix.Generator.create_file(task.test_path, contents)

        File.open!("mapping", [:append], fn file ->
          IO.puts(
            file,
            "#{task.module_path} #{problem.contest_path} #{task.task_screen_name}"
          )
        end)
      end
    )

    # mappingを読み込んで新しいものを正としたuniqをかけ、再度mappingに書き込む
    contents =
      File.read!("mapping")
      |> String.split(~r/\r\n|\n|\r/)
      |> Enum.reverse()
      |> Enum.uniq()
      |> Enum.reject(&match?("", &1))
      |> Enum.reverse()

    File.open!("mapping", [:write, :read], fn file ->
      :file.truncate(file)

      Enum.each(contents, &IO.puts(file, &1))
    end)
  end

  def submit(args) do
    File.read!("mapping")
    |> String.split(~r/\r\n|\n|\r/)
    |> Enum.map(&String.split/1)
    |> Enum.reject(&Enum.empty?/1)
    |> Enum.filter(fn [module_path, _contest_name, _task_screen_name] ->
      Enum.any?(args, fn arg -> String.starts_with?(module_path, arg) end)
    end)
    |> Enum.each(fn [module_path, contest_name, task_screen_name] ->
      source_code =
        File.read!(module_path)
        |> String.replace(~r/(?<=defmodule ).*?(?= do)/, "Main", global: false)

      Client.submit(contest_name, task_screen_name, source_code)
    end)

    :ok
  end

  defp get_login_info() do
    username =
      case Application.fetch_env(:kyopuro, :username) do
        {:ok, username} ->
          username

        :error ->
          Owl.IO.input(label: "ユーザー名")
      end

    password =
      case Application.fetch_env(:kyopuro, :password) do
        {:ok, password} ->
          password

        :error ->
          Owl.IO.input(label: "パスワード", secret: true)
      end

    %{username: username, password: password}
  end

  defp pad_trailing_for_console(string, count) do
    string <> String.duplicate(" ", count - count_width(string))
  end

  defp count_width(string) do
    String.split(string, "", trim: true)
    |> Enum.map(fn char ->
      # East Asian Widthについて
      # http://www.darkhorse.mydns.jp/blog/utf8-width
      case Unicode.EastAsianWidth.east_asian_width_category(char) do
        [:f] -> 2
        [:h] -> 1
        [:na] -> 1
        [:w] -> 2
        # East Asian Ambiguoustについてはすべて幅2として扱う
        [:a] -> 2
        [:n] -> 1
      end
    end)
    |> Enum.sum()
  end

  defp build_problem(contest, tasks) do
    problem = Kyopuro.Problem.new()

    # abc001
    contest_path = Path.basename(contest.link)
    # ABC001
    contest_module = String.upcase(contest_path)

    tasks =
      Enum.map(tasks, fn task ->
        test_cases = Client.test_cases(task)

        # a
        task_path = task.level
        # A
        task_module = String.upcase(task_path)
        # ATest
        task_test_module = task_module <> "Test"

        # Hoge.ABC001.A
        module = Module.concat([problem.app_module, contest_module, task_module])

        # lib/hoge/abc001/a.ex
        module_path =
          Path.join(["lib", problem.app, contest_path, String.downcase(task_path) <> ".ex"])

        # HogeTest/ABC001/ATest
        test_module =
          Module.concat([problem.app_test_module, contest_module, task_test_module])

        # test/hoge_test/abc001/a_test.exs
        test_path =
          Path.join([
            "test",
            problem.app_test,
            contest_path,
            String.downcase(task_path <> "_test.exs")
          ])

        %{
          task_screen_name: task.task_screen_name,
          module: module,
          module_path: module_path,
          test_module: test_module,
          test_path: test_path,
          test_cases: test_cases
        }
      end)

    %{
      problem
      | contest_path: contest_path,
        tasks: tasks
    }
  end

  defp select_contest(query), do: select_contest(Client.contests(query), query)

  @paze_size 10
  defp select_contest(original_contests, query, page_number \\ 1, inner_page_index \\ 0) do
    # ENHANCE: ページを指定してのページングできるようにしたい
    {%{has_prev_page: has_prev_page, has_next_page: has_next_page, contests: contests} =
       original_contests, page_number,
     inner_page_index} =
      cond do
        inner_page_index < 0 && original_contests.has_prev_page ->
          # ページ内インデックスが0未満なので前ページへ移動する
          page_number = page_number - 1
          original_contests = Client.contests(Map.put(query, "page", page_number))

          {original_contests, page_number,
           ceil(Enum.count(original_contests.contests) / @paze_size) - 1}

        inner_page_index > floor(Enum.count(original_contests.contests) / @paze_size) - 1 &&
            original_contests.has_next_page ->
          # ページ内インデックスが0ではない かつ ページ内インデックスがとり得る上限を超えているので次ページへ移動する
          {Client.contests(Map.put(query, "page", page_number + 1)), page_number + 1, 0}

        true ->
          # それ以外の場合はページ移動しない
          {original_contests, page_number, inner_page_index}
      end

    # コンテスト一覧（MAX50件）から10件区切りでページ内インデックスに該当する一覧を抜き出す
    contests =
      contests
      |> Enum.chunk_every(@paze_size)
      |> Enum.at(inner_page_index, [])

    contests =
      cond do
        inner_page_index == 0 &&
          original_contests.contests
          |> Enum.chunk_every(@paze_size)
          |> Enum.at(inner_page_index + 1) == nil && !has_prev_page && !has_next_page ->
          # ページ内インデックスが1 かつ 前のページが存在しない かつ ページ内インデックスが最後 かつ 次のページが存在しない場合、「前の10件」「次の10件」は表示しない
          contests

        inner_page_index == 0 && !has_prev_page ->
          # ページ内インデックスが1 かつ 前のページが存在しない場合、「前の10件」は表示しない
          contests ++ [%{contest_name: "次の10件", rated_target: "", link: ""}]

        original_contests.contests
        |> Enum.chunk_every(@paze_size)
        |> Enum.at(inner_page_index + 1) == nil &&
            !has_next_page ->
          # ページ内インデックスが最後 かつ 次のページが存在しない場合、「次の10件」は表示しない
          [%{contest_name: "前の10件", rated_target: "", link: ""}] ++ contests

        true ->
          # それ以外の場合は「前の10件」「次の10件」を表示する
          [%{contest_name: "前の10件", rated_target: "", link: ""}] ++
            contests ++ [%{contest_name: "次の10件", rated_target: "", link: ""}]
      end

    contest_name_max_width =
      Enum.reduce(contests, 0, fn contest, max ->
        max(count_width(contest.contest_name), max)
      end)

    rated_target_max_length =
      Enum.reduce(contests, 0, fn contest, max ->
        max(count_width(contest.rated_target), max)
      end)

    # ENHANCE: 将来的にはカーソルキーでの選択を実装したい
    contests
    |> Owl.IO.select(
      render_as: fn contest ->
        "#{pad_trailing_for_console(contest.contest_name, contest_name_max_width)} | #{pad_trailing_for_console(contest.rated_target, rated_target_max_length)}"
      end
    )
    |> case do
      %{contest_name: "前の10件"} ->
        select_contest(original_contests, query, page_number, inner_page_index - 1)

      %{contest_name: "次の10件"} ->
        select_contest(original_contests, query, page_number, inner_page_index + 1)

      contest ->
        contest
    end
  end

  defp select_task(tasks) do
    tasks_ = [%{level: "", task_name: "すべて", link: "", task_screen_name: ""} | tasks]

    level_max_width =
      Enum.reduce(tasks_, 0, fn task, max ->
        max(count_width(task.level), max)
      end)

    task_name_max_width =
      Enum.reduce(tasks_, 0, fn task, max ->
        max(count_width(task.task_name), max)
      end)

    tasks_
    |> Owl.IO.select(
      render_as: fn task ->
        "#{pad_trailing_for_console(task.level, level_max_width)} | #{pad_trailing_for_console(task.task_name, task_name_max_width)}"
      end
    )
    |> case do
      %{task_name: "すべて"} ->
        tasks

      task ->
        task
    end
  end
end
