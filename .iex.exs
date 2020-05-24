Application.put_env(:elixir, :ansi_enabled, true)

IEx.configure(
  colors: [
    syntax_colors: [
      # atom: , :string, :binary, :list, :number, :boolean, :nil
      number: [:light_red, :underline],
      binary: [:cyan, :underline],
      atom: :light_blue,
      string: :light_green,
      list: :magenta,
      boolean: :red,
      nil: [:magenta, :bright]
    ],
    ls_directory: :cyan,
    ls_device: :yellow,
    doc_code: :green,
    doc_inline_code: :magenta,
    doc_headings: [:cyan, :underline],
    doc_title: [:cyan, :bright, :underline]
  ],
  history_size: 500,
  inspect: [
    binaries: :infer,
    pretty: true,
    width: 80
  ],
  default_prompt: "<#{Mix.env()}> [#{IO.ANSI.cyan()}%counter#{IO.ANSI.reset()}] %node ->",
  alive_prompt: "<#{Mix.env()}> (#{IO.ANSI.cyan()}%counter#{IO.ANSI.reset()}) %node ->",
  width: 80
)

alias Hf.Repo
import Hf.Repo

alias Hf.Workers.{HelloWorld, RequestWorker}
import Ecto.Query
alias Hf.Domain.Variable
import Hf.LocalLogger

alias Hf.Http.Req.{
  Headers,
  Input,
  Method,
  Options,
  BuildRequest,
  Params,
  Body,
  Mock,
  Proxy,
  Head,
  UserAgent,
  Cookie
}

alias Hf.Http.Resp.{
  CodeMsg,
  FlokiParse,
  JsonParse,
  TextParse,
  TelemetryExec,
  ContentType,
  Unzip,
  BuildResponse
}

alias Hf.Domain
alias Hf.Util

alias Hf.Http
alias Hf.Http.Result.{Enqueue, SaveFile}
alias Hf.Http.Special.{Hook, Persist}
alias Hf.Http.Dynamic
alias Hf.Http.Custom
alias Hf.Http.Config

alias Hf.Http.Fetcher
alias Hf.Http.Tool
alias Hf.Http.Api
alias Hf.Http.Middleware
alias Hf.Http.Registry

alias HTTPoison.Error
alias HTTPoison.Request, as: Req
alias HTTPoison.Response, as: Resp
import Hf.Http.Fetcher

alias Hf.Domain.Job, as: J
alias Hf.Domain.Environment, as: Env
alias Hf.Domain.Error, as: E
alias Hf.Domain.Request, as: R
alias Hf.Domain.Api, as: A
alias Hf.Domain.Snapshot, as: S
alias Hf.Domain.History, as: H
alias Hf.Concern.Queryable, as: Q
import Hf.Concern.Queryable
alias Ecto.Adapters.SQL
alias Ecto.Query
import Hf
alias Hf.ReportError

require Hf.Macro
import Hf.Macro
