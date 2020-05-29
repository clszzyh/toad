use Hf.Http.Config

[
  %{
    name: :nhsoft_cloud_test,
    context: [url_prefix: "https://cloud-test.nhsoft.cn/authserver", module: "OMS"],
    pipes: [
      json_parse: true,
      code_msg: [],
      headers: [header_strategy: :json],
      oauth2: %{
        strategy: :client_credentials,
        client_id: "b847070c4f634804b120a3eb1836db02",
        client_secret: "31aae412e39c4f21b4254e613e0ce0f4",
        site: "https://cloud-test.nhsoft.cn/authserver"
      }
    ],
    tests: [%{kind: :meta, name: "module name", pattern: quote(do: %{context: %{module: "OMS"}})}]
  },
  %{
    name: :sidekiq_enqueue,
    input: [url_suffix: "/sidekiq/queues"],
    pipes: [
      headers: %{Authorization: "Basic <%= input.token %>"},
      floki_parse: %{
        enqueued:
          {"#page > div > div > div.col-sm-12.summary_bar > ul > li.enqueued.col-sm-1 > a > span.count",
           :text}
      }
    ],
    methods: [
      floki_parse: [
        args: quote(do: [%{enqueued: count}]),
        when: quote(do: is_binary(count)),
        body: quote(do: {:ok, String.to_integer(count)})
      ]
    ],
    tests: [
      %{
        kind: :rq,
        name: "enqueue",
        input: [%{}],
        pattern: quote(do: {:ok, %{enqueued: _}, _})
      }
    ]
  }
]
