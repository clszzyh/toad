defmodule Hf.Http.Req.Options do
  use Hf.Http.Middleware

  @options_map %{
    default: %{
      ssl: %{verify: :verify_none},
      hackney: %{pool: :default_pool},
      recv_timeout: 5_000,
      timeout: 5_000
    }
  }

  def pipe(%Api{options: %{} = options} = a, input) do
    {options, result} = build_options(a, input, options)
    {:ok, result, %Api{a | options: options}}
  end

  defp build_options(a, input, options, result \\ [])

  defp build_options(%Api{} = a, %{option_strategy: strategy} = input, %{} = options, result)
       when strategy != :none do
    opt = Map.fetch!(@options_map, strategy)

    build_options(
      a,
      %{input | option_strategy: :none},
      Tool.merge_map(options, opt),
      [{strategy, opt} | result]
    )
  end

  defp build_options(%Api{} = a, %{options: opt} = input, %{} = options, result)
       when is_list(opt) do
    build_options(a, %{input | options: Map.new(opt)}, options, result)
  end

  defp build_options(%Api{} = a, %{options: %{} = opt} = input, %{} = options, result) do
    build_options(
      a,
      %{input | options: :none},
      Tool.merge_map(options, opt),
      [{:manual, opt} | result]
    )
  end

  defp build_options(_, _, options, result), do: {options, result}
end
