defmodule Hf.Debugger do
  import Hf.LocalLogger

  defmacro __using__(opts) do
    quote do
      require IEx
      "-" |> String.duplicate(:io.columns() |> elem(1)) |> IO.write()
      info(["options", __MODULE__, unquote(opts)], pretty: true)
      warn(binding(), pretty: true)
      "-" |> String.duplicate(:io.columns() |> elem(1)) |> IO.write()
      # credo:disable-for-next-line
      IEx.pry()
    end
  end
end
