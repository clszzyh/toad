defmodule Hf.Macro do
  alias Hf.Domain.Snapshot, as: S
  alias Hf.Repo

  def hello_f(a) do
    IO.inspect(a)
    "hello: #{inspect(a)}"
  end

  defmacro hello_m(a) do
    IO.inspect(a)

    quote bind_quoted: [a: a] do
      var!(hello) = a
      "hello: #{inspect(a)}"
    end
  end

  defmacro save_snapshot! do
    quote do
      %S{} |> S.changeset(%{context: binding()}) |> Repo.insert!()
    end
  end

  defmacro rebinding!(ast) do
    {%_{context: context}, _} = Code.eval_quoted(ast, [], __ENV__)

    quote do
      unquote(
        for {k, v} <- context do
          quote do
            var!(unquote(Macro.var(k, nil))) = unquote(Macro.escape(v))
            {unquote(k), unquote(Macro.escape(v))}
          end
        end
      )
    end
  end
end
