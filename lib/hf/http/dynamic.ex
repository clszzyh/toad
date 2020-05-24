defmodule Hf.Http.Dynamic do
  @moduledoc false
  alias Hf.Domain.Api, as: A
  alias Hf.Http.{Ast, Registry}

  def compile(a, parent \\ "Custom")

  def compile(%A{} = a, parent), do: a |> Map.from_struct() |> compile(parent)

  def compile(%{methods: [_ | _] = methods} = config, parent) do
    old_pipes = config |> Map.get(:pipes, [])

    pipes =
      methods
      |> Enum.map(fn {k, _} -> {k, []} end)
      |> Enum.reject(&match?({:hook, _}, &1))
      |> Keyword.merge(old_pipes)

    register_compile(%{config | pipes: pipes}, parent)
  end

  def compile(%{} = config, parent) do
    register_compile(config, parent)
  end

  def register_compile(%{id: _} = config, parent) do
    result = do_compile(config, parent)
    :ok = result |> Registry.register()
    result
  end

  def register_compile(config, parent) do
    register_compile(config |> Map.put(:id, nil), parent)
  end

  def do_compile(%{name: atom_name} = config, parent) when is_binary(atom_name) do
    do_compile(%{config | name: String.to_atom(atom_name)}, parent)
  end

  def do_compile(%{name: atom_name, version: version, id: id} = config, parent)
      when is_integer(version) and is_atom(atom_name) do
    config_ast = Enum.map(config, &Ast.config_ast/1)

    ast =
      quote location: :keep do
        use Hf.Http.Api

        unquote(config_ast)
      end

    name = atom_name |> to_string |> Macro.camelize()
    module_name = Module.concat([Hf.Http, parent, name, "V#{version}"])

    case Code.ensure_compiled(module_name) do
      {:module, _} ->
        IO.puts("删除 #{module_name}")
        :code.purge(module_name)
        :code.delete(module_name)

      {:error, _} ->
        nil
    end

    {:module, final_module, _, _} = Module.create(module_name, ast, Macro.Env.location(__ENV__))
    {:ok, {{id, atom_name, version}, final_module}}
  rescue
    e ->
      {:error,
       {{id, atom_name, version},
        use(Hf.ReportError, type: :load_api, reason: e, stacktrace: __STACKTRACE__)}}
  end

  def do_compile(%{name: _} = config, parent),
    do: do_compile(Map.put(config, :version, 1), parent)
end
