defmodule Hf.Http.Common do
  @moduledoc false

  defmacro __using__(_) do
    quote do
      alias HTTPoison.Error
      alias HTTPoison.Request, as: Req
      alias HTTPoison.Response, as: Resp
      import Hf.LocalLogger

      alias Hf.Http.{
        Api,
        Ast,
        Core,
        Custom,
        Dynamic,
        Middleware,
        Persist,
        Registry,
        Request,
        Tool
      }

      alias Hf.Cache
      alias Hf.Util

      alias Hf.Debugger
      alias Hf.Domain
      alias Hf.Domain.Api, as: A
      alias Hf.Domain.Group, as: G
      alias Hf.Domain.Job, as: J
      alias Hf.Domain.Record, as: R
      alias Hf.Domain.Test, as: T
      alias Hf.Repo
      alias Hf.Workers.RequestWorker
    end
  end
end
