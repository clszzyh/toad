defmodule Hf.Worker do
  defmacro __using__(opt) do
    ast =
      for {name, arity} <- Hf.Repo.export_methods() do
        args = Macro.generate_arguments(arity, __MODULE__)

        quote do
          def unquote(name)(unquote_splicing(args)) do
            Repo.unquote(name)(query(), unquote_splicing(args))
          end
        end
      end

    quote do
      use Oban.Worker, unquote(opt)
      alias Hf.Domain
      alias Hf.Domain.Api, as: A
      alias Hf.Domain.Environment, as: E
      alias Hf.Domain.Job, as: J
      alias Hf.Domain.Record, as: R
      alias Hf.Http.{Api, Core}
      alias Hf.Repo
      alias Oban.{Beat, Job}
      import Ecto.Query, warn: false
      import Hf.LocalLogger

      def run!(args \\ %{}) do
        args |> __MODULE__.new() |> Oban.insert!()
      end

      def query do
        name = __MODULE__.__info__(:module) |> to_string |> String.trim_leading("Elixir.")
        Job |> where([j], j.worker == ^name)
      end

      def mock do
        perform(%Job{id: -1})
      end

      unquote(ast)
    end
  end
end
