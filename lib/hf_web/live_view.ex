defmodule HfWeb.LiveView do
  defmacro __using__(_opt) do
    quote do
      use HfWeb, :live_view
      alias Hf.Domain
      alias Hf.Domain.Job, as: J
      alias Hf.Domain.Request, as: R
      alias HTTPoison.Request, as: Req
      alias HTTPoison.Response, as: Resp
      alias Hf.Http.{Api, Fetcher}
      alias Hf.Util
    end
  end
end
