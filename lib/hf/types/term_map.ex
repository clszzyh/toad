defmodule Hf.Types.TermMap do
  @moduledoc false
  use Hf.Type, :term_map

  @impl Type
  def load(%{"name" => name, "value" => value}) do
    {:ok, {String.to_atom(name), Util.encode64_to_term(value)}}
  end

  @impl Type
  def dump({n, o}) do
    {:ok, %{"name" => n, "display" => inspect(o), "value" => Util.term_to_encode64(o)}}
  end
end
