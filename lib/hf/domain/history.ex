defmodule Hf.Domain.History do
  @moduledoc false
  use Hf.Schema

  schema "history" do
    field :pk, :integer
    field :table_name, :string
    field :op, :string
    field :query, :string
    field :app_session_user_id, :string
    field :data, :map
    timestamps(updated_at: false)
  end
end
