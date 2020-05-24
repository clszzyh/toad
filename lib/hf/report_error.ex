defmodule Hf.ReportError do
  alias Hf.Util

  def format_blamed(%{kind: kind, reason: error, stacktrace: stacktrace}) do
    {blamed, stacktrace} = Exception.blame(kind, error, stacktrace)

    Exception.format(kind, blamed, stacktrace)
  end

  defmacro __using__(options) do
    options = build_input(options)

    quote do
      alias Hf.Domain.Error, as: E
      alias Hf.Repo
      import unquote(__MODULE__)

      reason = unquote(options[:reason])
      kind = unquote(options[:kind]) || :error

      stacktrace =
        unquote(options[:stacktrace]) || self() |> Process.info(:current_stacktrace) |> elem(1)

      context = binding()
      format_blamed = format_blamed(%{kind: kind, reason: reason, stacktrace: stacktrace})

      Hf.LocalLogger.error([reason], box: :all)

      %E{}
      |> E.changeset(
        %{
          kind: kind,
          type: unquote(options[:type]),
          eid: unquote(options[:eid]),
          reason: Util.inspect_error(reason),
          format_blamed: format_blamed,
          context: context,
          stacktrace: stacktrace
        }
        |> Enum.reject(&match?({_, nil}, &1))
        |> Enum.into(%{})
      )
      |> Repo.insert!()

      reason
    end
  end

  defp build_input(options) when is_binary(options) or is_tuple(options), do: [reason: options]
  defp build_input(options) when is_list(options), do: options
end
