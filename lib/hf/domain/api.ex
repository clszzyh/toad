defmodule Hf.Domain.Api do
  @moduledoc false
  use Hf.Schema

  required [:name]

  permitted [
    :name,
    :group,
    :env_id,
    :state,
    :version,
    :url,
    :tags,
    :pipes,
    :payload,
    :methods,
    :kind,
    :context,
    :input,
    :tests
  ]

  schema "apis" do
    field :name, AtomString
    field :version, :integer, default: 1
    field :env_id, :integer
    field :group, AtomString
    field :state, ApiStates, default: :enabled
    field :kind, ApiKinds, default: :custom
    field :url, :string, default: "<%= input.url %>"
    field :tags, {:array, AtomOrTuple}, default: []
    field :pipes, {:array, TuplePipe}, default: []
    field :methods, {:array, TupleMethod}, default: []
    field :tests, {:array, NormalMap}, default: []
    field :context, {:array, TermMap}, default: []
    field :input, {:array, TermMap}, default: []
    field :payload, :map
    timestamps()

    has_many :reqs, Domain.Record, foreign_key: :api_id
    belongs_to :env, Domain.Env, foreign_key: :env_id, define_field: false
    belongs_to :g, Domain.Group, foreign_key: :group, references: :name, define_field: false

    has_many :hist, Domain.History, foreign_key: :pk, where: [table_name: "apis"]

    field :display_methods, :any, virtual: true
  end

  def default_query(%Query{} = q), do: q |> where([x], x.state != "deleted")

  def to_ast(string) when is_binary(string), do: string |> Code.string_to_quoted()

  def fill_display_methods(%__MODULE__{methods: methods} = a) do
    o =
      methods
      |> Enum.map(fn {k, v} ->
        {k, Enum.map(v, fn {k1, v1} -> {k1, display_methods({k1, v1})} end)}
      end)

    %__MODULE__{a | display_methods: o}
  end

  def display_methods({:args, v}), do: Enum.map(v, &Macro.to_string/1)
  def display_methods({:when, nil}), do: nil
  def display_methods({:when, v}), do: v |> Macro.to_string()

  def display_methods({:body, v}),
    do:
      v
      |> Macro.to_string()
      |> String.split("\n")
      |> Enum.map(&String.trim/1)
      |> Enum.reject(&match?(x when x in ["(", ")"], &1))
end
