defmodule Hf.Type do
  defmacro __using__(name) when is_atom(name) do
    quote do
      alias Ecto.Type
      alias Hf.Util
      @behaviour Type

      @impl Type
      def type, do: unquote(name)

      @impl Type
      def cast(value), do: {:ok, value}

      @impl Type
      def embed_as(_), do: :self
      @impl Type
      def equal?(term1, term2), do: term1 == term2

      @before_compile unquote(__MODULE__)
    end
  end

  defmacro __before_compile__(_env) do
    quote generated: true do
      def load(_), do: :error
      def dump(_), do: :error
    end
  end
end
