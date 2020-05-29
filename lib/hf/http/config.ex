defmodule Hf.Http.Config do
  @moduledoc false
  use Hf.Http.Common

  defmacro __using__(_) do
    quote do
      alias Hf.Domain.Api, as: A
      alias Hf.Domain.Group, as: G
      alias Hf.Domain.Variable, as: V
      alias Hf.Http.{Api, Core, Registry}
      alias Hf.Repo
      alias HTTPoison.Request, as: Req
      alias HTTPoison.Response, as: Resp
    end
  end

  @custom [
    %{
      name: :demo,
      kind: :builtin,
      version: 4,
      url: "mercury-mbox-test.nhsoft.cn/echo",
      tags: [:follow_redirect],
      pipes: [
        cookie: %{hello: "world"},
        json_parse: true,
        code_msg: []
      ]
    }
  ]

  @data @custom

  def data, do: @data

  def load_data, do: @data |> Enum.map(fn a -> Dynamic.compile(a, "dynamic") end)

  def load_apis, do: Domain.apis() |> Enum.map(&Dynamic.compile/1)

  def load do
    load_apis()
    load_data()
    :ok
  end
end
