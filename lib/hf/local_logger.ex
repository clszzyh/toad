defmodule Hf.LocalLogger do
  @moduledoc false
  require Logger
  import IO.ANSI
  alias Hf.Util

  @columns :io.columns() |> elem(1)
  @line "+" <> String.duplicate("─", @columns - 30) <> "+"

  @format [
    pretty: false,
    binaries: :infer,
    structs: true,
    syntax_colors: [
      # atom: , :string, :binary, :list, :number, :boolean, :nil
      number: [:light_red, :underline],
      binary: [:cyan, :underline],
      atom: :light_blue,
      string: :light_green,
      list: :magenta,
      boolean: :red,
      nil: [:magenta, :bright]
    ],
    ls_directory: :cyan,
    ls_device: :yellow,
    doc_code: :green,
    doc_inline_code: :magenta,
    doc_headings: [:cyan, :underline],
    doc_title: [:cyan, :bright, :underline]
  ]

  def format_options, do: @format

  def format(level, message, timestamp, metadata) do
    format_1(level, message, timestamp, metadata)
  rescue
    e -> "[ERROR] #{inspect({level, message, metadata})} -> #{inspect(e)}"
  end

  def format_1(:info, message, timestamp, metadata),
    do: format_2("[", "]", message, timestamp, metadata)

  def format_1(:warn, message, timestamp, metadata),
    do: format_2("(", ")", message, timestamp, metadata)

  def format_1(:error, message, timestamp, metadata),
    do: format_2("{", "}", message, timestamp, metadata)

  def format_1(:debug, message, timestamp, metadata),
    do: format_2("<", ">", message, timestamp, metadata)

  @padding state: 7, cost: 8
  def maybe_padding({index, count}, k) when k in [:i, :retry],
    do:
      "[#{inverse()}#{
        index |> to_string |> String.pad_leading(count |> to_string |> String.length(), "0")
      }/#{count}#{inverse_off()}]"

  def maybe_padding(v, k),
    do: (inverse() <> to_string(v) <> inverse_off()) |> String.pad_trailing(@padding[k] || 0)

  def format_2(s1, s2, message, timestamp, []), do: format_3(s1, s2, message, timestamp, "")

  def format_2(s1, s2, message, timestamp, [_ | _] = metadata) do
    res =
      for {k, v} when v not in [nil, "", {0, 0}, {nil, 0}, {0, nil}] <- metadata,
          do: "#{k}=#{v |> maybe_padding(k)} ",
          into: ""

    format_3(
      s1,
      s2,
      message,
      timestamp,
      res
    )
  end

  def format_3(s1, s2, message, timestamp, metadata) do
    "#{metadata}#{s1}#{underline()}#{timestamp |> format_date}#{no_underline()}#{s2} #{message}\n"
  end

  defp format_date({{_, month, day}, {hour, min, sec, _}}) do
    # {:ok, ndt} = NaiveDateTime.new(year, month, day, hour, min, sec, {millis, 3})
    # NaiveDateTime.to_iso8601(ndt, :extended)
    sec = sec |> to_string |> String.pad_leading(2, "0")
    min = min |> to_string |> String.pad_leading(2, "0")
    hour = hour |> to_string |> String.pad_leading(2, "0")
    "#{month}-#{day} #{hour}:#{min}:#{sec}"
  end

  defdelegate metadata, to: Logger
  defdelegate metadata(list), to: Logger
  defdelegate reset_metadata, to: Logger

  def info(s, opt \\ []), do: logger(:info, s, opt)
  def debug(s, opt \\ []), do: logger(:debug, s, opt)
  def warn(s, opt \\ []), do: logger(:warn, s, opt)
  def error(s, opt \\ []), do: logger(:error, s, opt)

  def inspect_logger(s, _) when is_binary(s), do: s

  def inspect_logger({:pad_leading, n, s}, options) when is_integer(n) do
    s |> Util.inspect_binary(options) |> String.pad_leading(n, " ")
  end

  def inspect_logger({:pad_trailing, n, s}, options) when is_integer(n) do
    s |> Util.inspect_binary(options) |> String.pad_trailing(n, " ")
  end

  def inspect_logger({:slice, {n1, n2}, s}, options) when is_integer(n1) and is_integer(n2) do
    case s do
      a when is_binary(a) -> String.slice(a, 0, n1)
      s -> s |> Util.inspect_binary(options) |> String.slice(0, n2)
    end
  end

  def inspect_logger(s, options), do: inspect(s, options)

  def logger(name, s, opt \\ [])

  def logger(name, s, opt) when is_list(s) do
    options = Keyword.merge(@format, opt)

    logger_1(
      name,
      s
      |> Enum.filter(&match?(x when x not in [nil, ""], &1))
      |> Enum.map_join(" ", fn x -> inspect_logger(x, options) end),
      options
    )
  end

  def logger(name, s, opt), do: logger_1(name, s |> inspect(Keyword.merge(@format, opt)), opt)

  def logger_1(name, s, options) do
    :hf
    |> Application.get_env(:app_log_level, :debug)
    |> Logger.compare_levels(name)
    |> case do
      :gt -> nil
      _ -> logger_2(name, s, options)
    end
  end

  def logger_2(level, s, options) do
    s =
      if options[:prefix] do
        options[:prefix] <> s
      else
        s
      end

    boxed_s = "| " <> IO.ANSI.reset() <> s

    case options[:box] do
      :all ->
        logger_3(level, @line)
        logger_3(level, boxed_s)
        logger_3(level, @line)

      nil ->
        logger_3(level, s)

      :before ->
        logger_3(level, @line)
        logger_3(level, boxed_s)

      :after ->
        logger_3(level, boxed_s)
        logger_3(level, @line)
    end
  end

  def logger_3(:info, s) when is_binary(s), do: Logger.info(s, ansi_color: [:magenta, :italic])
  def logger_3(:debug, s) when is_binary(s), do: Logger.debug(s, ansi_color: [:cyan, :italic])
  def logger_3(:warn, s) when is_binary(s), do: Logger.warn(s, ansi_color: [:yellow, :italic])
  def logger_3(:error, s) when is_binary(s), do: Logger.error(s, ansi_color: [:red, :italic])

  def verbose(o) do
    Logger.configure(truncate: :infinity)
    info(o, structs: false, pretty: true, limit: :infinity)
    Logger.configure(truncate: 8192)
    nil
  end
end
