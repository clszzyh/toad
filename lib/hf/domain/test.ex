defmodule Hf.Domain.Test do
  @moduledoc false
  use Hf.Schema

  required [:name, :kind, :source, :config]
  permitted [:api_id, :name, :kind, :source, :config, :matched, :result]

  schema "tests" do
    field :api_id, :integer
    field :source, AtomString
    field :name, :string
    field :kind, AtomString
    field :config, NormalMap
    field :matched, TestMatches, default: :unknown
    field :result, Term
    field :payload, :map, autogenerate: {Schema, :get_payload, []}
    timestamps()

    belongs_to :a, Domain.Api, foreign_key: :api_id, define_field: false
    has_one :req, Domain.Record, foreign_key: :test_id
  end
end
