defmodule Hf.Domain.Env do
  @moduledoc false
  use Hf.Schema

  display [:name]
  required [:name]
  permitted [:name]

  @derive [
    {Jason.Encoder, only: [:id, :created_at, :updated_at | @display_fields || []]},
    {Inspect, except: @except_fields || []}
  ]
  schema "environments" do
    field :name, :string
    timestamps()

    has_many :apis, Domain.Api, foreign_key: :env_id
  end
end
