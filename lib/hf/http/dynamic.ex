defmodule Hf.Http.Dynamic do
  @moduledoc false
  alias Hf.Domain
  alias Hf.Domain.Api, as: A
  alias Hf.Domain.Group, as: G
  alias Hf.Http.{Ast, Registry}

  @default_config %{
    version: 1,
    pipes: [],
    methods: [],
    tags: [],
    context: [],
    input: [],
    tests: [],
    g: :none
  }

  def compile(a, parent \\ "custom")

  def compile(%A{} = a, parent), do: a |> Map.from_struct() |> compile(parent)

  def compile(%{} = config, parent) do
    %{pipes: pipes, methods: methods} = config = @default_config |> Map.merge(config)

    pipes =
      methods
      |> Enum.map(fn {k, _} -> {k, []} end)
      |> Enum.reject(&match?({:hook, _}, &1))
      |> Keyword.merge(pipes)

    register_compile(%{config | pipes: pipes}, parent)
  end

  def register_compile(%{id: _} = config, parent) do
    result = wrapper_compile(config, parent)
    :ok = result |> Registry.register()
    result
  end

  def register_compile(config, parent) do
    register_compile(config |> Map.put(:id, nil), parent)
  end

  def wrapper_compile(%{name: atom_name} = config, parent) when is_binary(atom_name) do
    wrapper_compile(%{config | name: String.to_atom(atom_name)}, parent)
  end

  def wrapper_compile(%{name: atom_name, version: version, id: id} = config, parent) do
    {:module, final_module, _, _} = do_compile(config, parent)
    {:ok, {{id, atom_name, version}, final_module}}
  rescue
    e ->
      {:error,
       {{id, atom_name, version},
        use(Hf.ReportError, type: :load_api, reason: e, stacktrace: __STACKTRACE__)}}
  end

  def do_compile(%{g: :none, group: group} = config, parent) when not is_nil(group) do
    do_compile(%{config | g: Domain.one!(G, %{by: [name: group]})}, parent)
  end

  def do_compile(
        %{
          g: %G{
            pipes: g_pipes,
            context: g_context,
            methods: g_methods,
            tests: g_tests,
            tags: g_tags,
            input: g_input
          },
          pipes: pipes,
          methods: methods,
          tests: tests,
          tags: tags,
          context: context,
          input: input
        } = config,
        parent
      ) do
    config
    |> Map.merge(%{
      group: nil,
      g: nil,
      pipes: g_pipes ++ pipes,
      methods: g_methods ++ methods,
      tags: g_tags ++ tags,
      tests: g_tests ++ tests,
      context: g_context |> Kernel.++(context) |> Map.new(),
      input: g_input |> Kernel.++(input) |> Map.new()
    })
    |> do_compile(parent)
  end

  def do_compile(
        %{
          name: atom_name,
          version: version,
          pipes: _,
          methods: _,
          tags: _,
          tests: _,
          context: _,
          input: _
        } = config,
        parent
      )
      when is_integer(version) and is_atom(atom_name) do
    config_ast = Enum.map(config, &Ast.config_ast/1)
    name = atom_name |> to_string |> Macro.camelize()
    module_name = Module.concat([Hf.Http, Macro.camelize(parent), name, "V#{version}"])
    file = Path.join([__DIR__, "#{parent}/#{atom_name}_v#{version}.ex"])

    ast =
      quote location: :keep, file: file do
        @file unquote(file)
        use Hf.Http.Api

        unquote(config_ast)
      end

    # IO.inspect({file, Macro.Env.location(__ENV__)})

    case Code.ensure_compiled(module_name) do
      {:module, _} ->
        IO.puts("删除 #{module_name}")
        :code.purge(module_name)
        :code.delete(module_name)

      {:error, _} ->
        nil
    end

    Module.create(module_name, ast, file: file, line: 0)
  end
end
