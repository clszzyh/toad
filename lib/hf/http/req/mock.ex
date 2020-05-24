defmodule Hf.Http.Req.Mock do
  use Hf.Http.Middleware

  @urls %{
    demo: "mercury-mbox-test.nhsoft.cn/echo",
    httpbin: "httpbin.org/anything"
  }

  def pipe(%Api{url: old_url} = a, %{mock: kind}) do
    new_url = Map.fetch!(@urls, kind)
    {:ok, {kind, new_url, old_url}, %Api{a | url: new_url}}
  end
end
