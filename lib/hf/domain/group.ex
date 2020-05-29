defmodule Hf.Domain.Group do
  @moduledoc false
  use Hf.Schema

  required [:name]
  permitted [:name, :tags, :pipes, :methods, :context, :input, :tests]

  schema "groups" do
    field :name, AtomString
    field :tags, {:array, AtomOrTuple}, default: []
    field :pipes, {:array, TuplePipe}, default: []
    field :methods, {:array, TupleMethod}, default: []
    field :tests, {:array, NormalMap}, default: []
    field :context, {:array, TermMap}, default: []
    field :input, {:array, TermMap}, default: []
    field :payload, :map, autogenerate: {Schema, :get_payload, []}
    timestamps()

    has_many :hist, Domain.History, foreign_key: :pk, where: [table_name: "groups"]
    has_many :apis, Domain.Api, foreign_key: :group, references: :name
  end
end
