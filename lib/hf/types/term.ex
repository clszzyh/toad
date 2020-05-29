defmodule Hf.Types.Term do
  @moduledoc false
  use Hf.Type, :term

  @impl Type
  def load(value) do
    {:ok, Util.encode64_to_term(value)}
  end

  @impl Type
  def dump(value) do
    {:ok, Util.term_to_encode64(value)}
  end
end
