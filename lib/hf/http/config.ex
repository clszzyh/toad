defmodule Hf.Http.Config do
  @moduledoc false
  use Hf.Http.Common

  defmacro __using__(_) do
    quote do
      alias Hf.Domain.Api, as: A
      alias Hf.Http.Api
      alias Hf.Repo
      alias HTTPoison.Request, as: Req
      alias HTTPoison.Response, as: Resp
    end
  end

  @custom []

  @data @custom

  def data, do: @data

  def load_data, do: @data |> Enum.map(fn a -> Dynamic.compile(a, "Dynamic") end)

  def load_apis, do: Domain.apis() |> Enum.map(&Dynamic.compile/1)

  def load do
    load_data()
    load_apis()
    :ok
  end
end
