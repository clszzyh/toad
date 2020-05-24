defmodule Hf.Types.AtomString do
  @moduledoc false
  use Hf.Type, :atom_string

  @impl Type
  def load(v) when is_binary(v), do: {:ok, String.to_atom(v)}

  @impl Type
  def dump(v) when is_atom(v), do: {:ok, to_string(v)}
  def dump(v) when is_binary(v), do: {:ok, v}
end
