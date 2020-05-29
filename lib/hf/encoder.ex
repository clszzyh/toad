defmodule Hf.Encoder do
  @moduledoc false
  alias Jason.Encoder

  defimpl Encoder, for: [Tuple] do
    def encode(data, opts) when is_tuple(data) do
      data
      |> Tuple.to_list()
      |> Encoder.List.encode(opts)
    end
  end

  defimpl Encoder, for: [MapSet, Range, Stream] do
    def encode(struct, opts) do
      Jason.Encode.list(Enum.to_list(struct), opts)
    end
  end

  # alias Hf.Domain.Record, as: R
  # defimpl Encoder, for: R do
  #   def encode(struct, opts) do
  #     struct
  #     |> Map.put(:valid_trace, R.valid_trace(struct))
  #     |> Encoder.List.encode(opts)
  #   end
  # end
end
