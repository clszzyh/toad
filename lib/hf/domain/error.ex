defmodule Hf.Domain.Error do
  @moduledoc false
  use Hf.Schema

  display [:kind, :type, :eid, :format_blamed, :reason, :stacktrace, :context]
  required [:reason]
  permitted [:kind, :type, :eid, :format_blamed, :reason, :stacktrace, :context, :payload]

  schema "errors" do
    field :kind, ErrorKinds
    field :type, ErrorTypes, default: 0
    field :eid, :integer
    field :format_blamed, :string
    field :reason, :string
    field :stacktrace, {:array, StacktraceMap}
    field :context, {:array, TermMap}
    field :payload, :map, autogenerate: {Schema, :get_payload, []}
    timestamps()
  end

  defshow :filter_stacktrace do
    %__MODULE__{stacktrace: stacktrace} = o ->
      %__MODULE__{
        o
        | stacktrace: stacktrace |> Enum.filter(&match?(%{options: %{file: "lib/hf" <> _}}, &1))
      }
  end
end
