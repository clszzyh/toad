defmodule Hf.Domain.Record do
  @moduledoc false
  use Hf.Schema

  required [:url, :source, :state]

  permitted [
    :cost,
    :input,
    :version,
    :job_id,
    :api_id,
    :parent_id,
    :test_id,
    :raw,
    :url,
    :source,
    :state,
    :method,
    :target,
    :payload,
    :history,
    :content_type,
    :data,
    :extra,
    :proxy,
    :attempt,
    :trace,
    :result,
    :proxy_id
  ]

  # except [:history, :raw]

  @derive [
    {Jason.Encoder, only: [:id, :created_at, :updated_at | @display_fields || []]},
    {Inspect, except: @except_fields || []}
  ]
  schema "records" do
    field :state, RequestStates
    field :method, RequestMethods

    field :content_type, RequestContentTypes, default: :none

    field :source, AtomString
    field :result, DynamicString
    field :version, :integer
    field :job_id, :integer
    field :api_id, :integer
    field :attempt, :integer
    field :parent_id, :integer
    field :proxy_id, :integer
    field :test_id, :integer
    field :url, :string
    field :cost, :integer
    field :target, :string
    field :proxy, :string

    field :history, {:array, :map}, default: []

    field :trace, {:array, TraceMap}, default: []
    field :input, :map
    field :extra, :map
    field :payload, {:map, :any}, default: %{}

    field :data, DynamicString
    field :raw, :binary
    timestamps()

    field :api, :any, virtual: true
    field :valid_trace, :any, virtual: true

    belongs_to :job, Domain.Job, foreign_key: :job_id, define_field: false
    belongs_to :test, Domain.Test, foreign_key: :test_id, define_field: false
    belongs_to :a, Domain.Api, foreign_key: :api_id, define_field: false
    belongs_to :parent, __MODULE__, foreign_key: :parent_id, define_field: false
    has_many :childs, __MODULE__, foreign_key: :parent_id
  end

  # defchangeset :remove_invalid_data do
  #   %Changeset{changes: %{data: data}} = changeset ->
  #     use Hf.Debugger
  #     if String.valid?(data), do: changeset, else: put_change(changeset, :data, "invalid")
  # end

  defchangeset :set_history do
    %Changeset{
      changes: %{state: new_state} = changes,
      data: %__MODULE__{
        history: history,
        state: old_state,
        result: old_result,
        attempt: attempt,
        version: version
      }
    } = changeset
    when is_list(history) ->
      put_change(changeset, :history, [
        %{
          "index" => Enum.count(history),
          "now" => Util.now(:verbose),
          "old_result" => old_result,
          "old_state" => old_state,
          "new_state" => new_state,
          "version" => version,
          "attempt" => attempt,
          "payload" => Schema.get_payload(),
          "changes" => changes |> Map.drop([:trace, :payload, :data, :raw, :state])
        }
        | history
      ])
  end

  defshow :fill_valid_trace do
    %__MODULE__{trace: trace} = o ->
      %__MODULE__{o | valid_trace: trace |> Enum.reject(&match?({_, {_, {:ignored, _}}}, &1))}
  end
end
