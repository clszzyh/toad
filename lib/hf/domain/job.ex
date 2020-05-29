defmodule Hf.Domain.Job do
  @moduledoc false
  use Hf.Schema

  schema "oban_jobs" do
    field :state, :string, default: "available"
    field :queue, :string, default: "default"
    field :worker, :string
    field :args, :map
    field :errors, {:array, :map}, default: []
    field :tags, {:array, :string}, default: []
    field :attempt, :integer, default: 0
    field :attempted_by, {:array, :string}
    field :max_attempts, :integer, default: 20
    field :priority, :integer, default: 0
    field :attempted_at, :utc_datetime_usec
    field :completed_at, :utc_datetime_usec
    field :discarded_at, :utc_datetime_usec
    field :inserted_at, :utc_datetime_usec
    field :scheduled_at, :utc_datetime_usec
    field :unique, :map, virtual: true
    field :unsaved_error, :map, virtual: true

    field :api, :any, virtual: true
    has_one :req, Domain.Record, foreign_key: :job_id
  end

  def compose_query(%Query{} = query, {:join, {kind, :req}}) when kind in [:inner, :left] do
    query |> join(kind, [j], assoc(j, :req), as: :req)
  end
end
