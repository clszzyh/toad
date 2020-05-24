defmodule Hf.Domain.Variable do
  @moduledoc false
  use Hf.Schema

  display [:desc, :key, :env, :value, :payload]
  except [:payload]
  required [:key, :value]
  permitted [:key, :value, :desc, :payload, :env]

  @derive [
    {Jason.Encoder, only: [:id, :created_at, :updated_at | @display_fields || []]},
    {Inspect, except: @except_fields || []}
  ]
  schema "variables" do
    field :env, :string, default: "default"
    field :key, :string
    field :value, :string
    field :desc, :string

    field :payload, :map
    timestamps()
  end
end
