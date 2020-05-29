## README

A spider manager platform.

Usage:

```elixir
%{
    name: :dingding,
    url: "https://oapi.dingtalk.com/robot/send",
    version: 2,
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
    ],
    tests: [
      %{
        kind: :rq,
        name: "empty rq",
        input: [%{}],
        pattern: quote(do: {:ok, [_ | _], _})
      }
    ]
}
```
