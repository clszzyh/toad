defmodule Hf.Domain.Snapshot do
  @moduledoc false
  use Hf.Schema

  display [:context]
  permitted [:context, :payload]

  schema "bindings" do
    field :context, {:array, TermMap}
    field :payload, :map, autogenerate: {Schema, :get_payload, []}
    timestamps()
  end
end
