defmodule Hf.Types.NormalMap do
  @moduledoc false
  use Hf.Type, :normal_map

  @impl Type
  def load(%{} = map) do
    {:ok, map |> Enum.into(%{}, fn {k, v} -> {String.to_atom(k), Util.load_value(v)} end)}
  end

  @impl Type
  def dump(%{} = map) do
    {:ok, map |> Enum.into(%{}, fn {k, v} -> {to_string(k), Util.dump_value(v)} end)}
  end
end
