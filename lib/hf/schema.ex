defmodule Hf.Schema do
  @attributes [
    display_fields: false,
    except_fields: false,
    required_fields: false,
    permitted_fields: false,
    show_methods: true,
    changesets: true
  ]

  def get_payload do
    %{
      "pid" => :erlang.pid_to_list(self()),
      "version" => Mix.Project.config()[:version],
      "node" => node(),
      "node_name" => Oban.Config.node_name(),
      "mix_env" => System.get_env("MIX_ENV"),
      "git_rev" => System.get_env("GIT_REV")
    }
  end

  defmacro __using__(_opt) do
    attributes_ast =
      for {name, accumulate} <- @attributes do
        quote do
          Module.register_attribute(__MODULE__, unquote(name), accumulate: unquote(accumulate))
        end
      end

    ast =
      for {name, arity} <- Hf.Repo.export_methods() do
        args = Macro.generate_arguments(arity, __MODULE__)

        quote do
          def unquote(name)(unquote_splicing(args)) do
            Repo.unquote(name)(__MODULE__, unquote_splicing(args))
          end
        end
      end

    quote do
      use Ecto.Schema
      import Ecto.Changeset
      alias Ecto.Changeset
      import EctoEnum
      import Ecto.Query
      alias Ecto.Query
      import Hf.LocalLogger

      import unquote(__MODULE__)
      alias unquote(__MODULE__)

      alias Hf.Domain
      alias Hf.Repo

      alias Hf.Types.{
        AtomOrTuple,
        AtomString,
        DynamicString,
        NormalMap,
        StacktraceMap,
        Term,
        TermMap,
        TraceMap,
        TupleMethod,
        TuplePipe
      }

      alias Hf.Util
      unquote(ast)
      unquote(attributes_ast)

      def tv do
        __MODULE__ |> Repo.tail() |> verbose
      end

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(env) do
    display_fields = env.module |> Module.get_attribute(:display_fields) || []
    except_fields = env.module |> Module.get_attribute(:except_fields) || []
    required_fields = env.module |> Module.get_attribute(:required_fields) || []
    permitted_fields = env.module |> Module.get_attribute(:permitted_fields) || []

    quote generated: true do
      alias Ecto.Query

      def compose_query(%Query{}, a), do: {:error, "[#{__MODULE__}]: #{inspect(a)}"}
      defoverridable compose_query: 2

      def default_query(%Query{} = q), do: q
      defoverridable default_query: 1

      def meta do
        %{
          display_fields: unquote(display_fields),
          except_fields: unquote(except_fields),
          required_fields: unquote(required_fields),
          permitted_fields: unquote(permitted_fields),
          show_methods: @show_methods,
          changesets: @changesets
        }
      end

      def show(%__MODULE__{} = a) do
        @show_methods
        |> Enum.reduce(a, fn f, o ->
          apply(__MODULE__, f, [o])
        end)
      end

      def changeset(obj, attrs) do
        changeset =
          obj
          |> cast(attrs, unquote(permitted_fields))
          |> validate_required(unquote(required_fields))

        @changesets
        |> Enum.uniq()
        |> Enum.reduce_while(changeset, fn
          x, %{valid?: false} = changeset ->
            {:halt, changeset}

          x, changeset ->
            apply(__MODULE__, x, [changeset])
            |> case do
              %{valid?: false} = changeset -> {:halt, changeset}
              %{valid?: true} = changeset -> {:cont, changeset}
            end
        end)
      end
    end
  end

  defmacro display([_ | _] = fields) do
    quote location: :keep, bind_quoted: [fields: fields] do
      @display_fields fields
    end
  end

  defmacro except([_ | _] = fields) do
    quote location: :keep, bind_quoted: [fields: fields] do
      @except_fields fields
    end
  end

  defmacro required([_ | _] = fields) do
    quote location: :keep, bind_quoted: [fields: fields] do
      @required_fields fields
    end
  end

  defmacro permitted([_ | _] = fields) do
    quote location: :keep, bind_quoted: [fields: fields] do
      @permitted_fields fields
    end
  end

  defmacro defshow(name, do: block) do
    quote do
      def unquote(name)(c) do
        case c do
          unquote(block)
        end
      end

      @show_methods unquote(name)
    end
  end

  defmacro defchangeset(name, do: block) do
    new_block = block ++ quote do: (other -> other)

    quote do
      def unquote(name)(c) do
        case c do
          unquote(new_block)
        end
      end

      @changesets unquote(name)
    end
  end
end
