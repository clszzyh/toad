defmodule Hf.Types.AtomOrTuple do
  @moduledoc false
  use Hf.Type, :atom_or_tuple

  @impl Type
  def load(v) when is_binary(v) do
    v
    |> String.split("=")
    |> case do
      [one] -> {:ok, String.to_atom(one)}
      [a, b | []] -> {:ok, {String.to_atom(a), String.to_atom(b)}}
    end
  end

  @impl Type
  def dump(v) when is_binary(v), do: {:ok, v}
  def dump(v) when is_atom(v), do: {:ok, to_string(v)}
  def dump({k, v}) when is_atom(k) and is_atom(v), do: {:ok, "#{k}=#{v}"}
end
