# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Hf.Repo.insert!(%Hf.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

use Hf.Http.Config

A |> Repo.delete_all()

[
  %{name: :any, kind: :builtin},
  %{
    name: :httpbin,
    kind: :builtin,
    url: "httpbin.org/<%= method %>",
    pipes: [cookie: %{hello: "world"}, json_parse: true]
  },
  %{
    name: :download,
    kind: :builtin,
    tags: ["follow_redirect", "head"],
    pipes: [save_file: %{target: [:resp, :body]}]
  },
  %{
    name: :demo,
    kind: :builtin,
    url: "mercury-mbox-test.nhsoft.cn/echo",
    tags: [:follow_redirect, "retry=local_proxy_http"],
    pipes: [cookie: %{hello: "world"}, json_parse: true, code_msg: []]
  },
  %{
    name: :demo,
    version: 2,
    url: "mercury-mbox-test.nhsoft.cn/echo",
    tags: [:follow_redirect, retry: :local_proxy_http],
    pipes: [cookie: %{hello: "world", version: 2}, json_parse: true, code_msg: []]
  },
  %{
    name: :a2u,
    kind: :builtin,
    url: "https://raw.githubusercontent.com/a2u/free-proxy-list/master/free-proxy-list.txt",
    pipes: [text_parse: {:string_split, "\n"}]
  },
  %{
    name: :demo,
    version: 3,
    url: "mercury-mbox-test.nhsoft.cn/echo",
    tags: [:follow_redirect, "mock_retry=resp"],
    pipes: [cookie: %{hello: "world", version: 2}, json_parse: true, code_msg: []]
  },
  %{name: :baidu, url: "www.baidu.com", pipes: [:floki_parse]},
  %{
    name: :migu_search,
    url: "http://music.migu.cn/v3/search?keyword=<%= input.keyword %>",
    pipes: [
      options: [follow_redirect: true],
      headers: %{
        Accept: "*/*",
        Referer: "http://music.migu.cn/v3",
        Host: "music.migu.cn",
        Accept_Encoding: "identity;q=1, *;q=0",
        Accept_Language: "en,zh;q=0.9",
        Cache_Control: "no-cache"
      }
    ]
  },
  %{
    name: :dingding,
    url: "https://oapi.dingtalk.com/robot/send",
    pipes: [
      method: :post,
      headers: [header_strategy: :json],
      params: %{access_token: "6fc5a17c2f692bc6f2b9693e6e9216985580b8a01f4de9e8ab2f6a945bfc1f71"}
    ],
    methods: [
      body: [
        args: quote(do: [%Api{body: body}, %{}, {:ok, _}]),
        when: quote(do: is_binary(body) or is_atom(body)),
        body:
          quote(
            do:
              {:req_body,
               %{msgtype: "text", at: %{isAtAll: false}, text: %{content: "oms #{body}"}}}
          )
      ],
      json_parse: [
        args: quote(do: [%{"errcode" => 0, "errmsg" => result}]),
        body: quote(do: {:ok, result})
      ],
      json_parse: [
        args: quote(do: [%{"errcode" => err, "errmsg" => res}]),
        body: quote(do: {:error, "#{err} #{res}"})
      ]
    ]
  }
]
|> Enum.map(fn a ->
  %A{} |> A.changeset(a) |> Repo.insert!()
end)
