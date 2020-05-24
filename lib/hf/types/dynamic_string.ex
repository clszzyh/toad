defmodule Hf.Types.DynamicString do
  @moduledoc false
  use Hf.Type, :dynamic_string

  @json_prefix "[json]"
  @term_prefix "[term]"

  @impl Type
  def load(@json_prefix <> v), do: Jason.decode(v)
  def load(@term_prefix <> v), do: Util.encode64_to_term(v)

  def load(v) when is_binary(v) do
    if String.valid?(v) do
      {:ok, v}
    else
      {:error, "invalid string"}
    end
  end

  @impl Type
  def dump(v) when is_binary(v), do: {:ok, v}

  def dump(v) when is_list(v) or is_map(v) do
    v
    |> Jason.encode()
    |> case do
      {:ok, x} -> {:ok, @json_prefix <> x}
      other -> other
    end
  end

  def dump(v) do
    {:ok, @term_prefix <> Util.term_to_encode64(v)}
  end
end
