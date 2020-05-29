use Hf.Http.Config

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
    name: :flower_dashboard,
    url: "http://oms.nhsoft.cn/flower/dashboard?json=1",
    pipes: [headers: %{Authorization: "Basic YWRtaW46dThSNkNJWUh6OA=="}],
    methods: [json_parse: quote(do: [args: [%{"data" => obj}], body: {:resp_body, obj}])]
  },
  %{
    name: :mbox_sidekiq,
    url: "https://mercury-mbox.nhsoft.cn",
    group: :sidekiq_enqueue,
    input: [token: "YWRtaW46OGVmYjAzNmE0M2I4Y2RmZjkyMmJjMjFlYzc1MDRkOTU="]
  },
  %{
    name: :internal_sidekiq,
    group: :sidekiq_enqueue,
    url: "http://114.55.239.206:7666",
    input: [token: "YWRtaW46Tmhzb2Z0MTIz"]
  },
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
  },
  %{
    name: :gateway_apis,
    group: :nhsoft_cloud_test,
    url: "/apis",
    methods: [
      code_msg: [
        args: quote(do: [body]),
        when: quote(do: is_list(body)),
        body: quote(do: {:resp_body, body |> Enum.filter(&match?(%{"module" => @module}, &1))})
      ]
    ],
    tests: [
      %{
        kind: :rq,
        name: "empty rq",
        input: [%{}],
        pattern: quote(do: {:ok, [_ | _], _})
      }
    ]
  },
  %{
    name: :gateway_api_find,
    group: :nhsoft_cloud_test,
    url: "/apis/",
    tags: [:restful_i_as_url_suffix]
  },
  %{
    name: :gateway_api_delete,
    group: :nhsoft_cloud_test,
    url: "/apis/",
    tags: [:restful_i_as_url_suffix],
    pipes: [method: :delete]
  },
  %{
    name: :gateway_api_save,
    group: :nhsoft_cloud_test,
    url: "/apis/",
    pipes: [method: :post],
    methods: [
      body: [
        args: quote(do: [%Api{input: input} = a, %{name: name, desc: desc, path: path}, _]),
        body:
          quote(
            do:
              (
                body = %{
                  description: desc,
                  path: path,
                  version: 1,
                  module: @module,
                  created_at: "<%= input.now %>"
                }

                {:ok, body, %Api{a | body: body, input: input |> Map.put(:url_suffix, name)}}
              )
          )
      ]
    ]
  }
]
