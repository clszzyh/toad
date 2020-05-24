defmodule Hf.Util do
  @moduledoc false

  def atomize_keys(o, options \\ [])
  def atomize_keys(%_{} = map, _), do: map
  def atomize_keys(%{} = map, _), do: map |> Enum.into(%{}, &atomize_keys/1)
  def atomize_keys([_ | _] = list, _), do: Enum.map(list, &atomize_keys/1)
  def atomize_keys(key, force: true) when is_binary(key), do: String.to_atom(key)
  def atomize_keys(key, _) when is_binary(key) and byte_size(key) <= 10, do: String.to_atom(key)
  def atomize_keys({key, v}, _), do: {atomize_keys(key, force: true), atomize_keys(v)}
  def atomize_keys(key, _), do: key

  def modules do
    {:ok, list} = :application.get_key(:hf, :modules)
    list
  end

  def compact(%{} = map), do: map |> Enum.reject(&match?(x when x in [nil, ""], &1))

  def term_to_encode64(s), do: s |> :erlang.term_to_binary() |> Base.encode64(padding: false)
  def encode64_to_term(s), do: s |> Base.decode64!(padding: false) |> :erlang.binary_to_term()

  @timezone "Asia/Shanghai"

  @time_format %{
    normal: "{YYYY}-{0M}-{0D} {h24}:{m}:{s}",
    date: "{YY}-{0M}-{0D}",
    verbose: "{YYYY}-{0M}-{0D} {h24}:{m}:{s}{ss}"
  }
  @format_kinds Map.keys(@time_format)

  def now(kind \\ :normal, t \\ Timex.now())
  def now(kind, t), do: now_1(kind, Timex.Timezone.convert(t, @timezone))
  defp now_1(:related, t), do: t |> time_distance
  defp now_1(:combined, t), do: "#{now(:normal, t)}, #{now(:related, t)}"

  defp now_1(kind, t) when kind in @format_kinds,
    do: Timex.format!(t, Map.fetch!(@time_format, kind))

  @units %{
    "microsecond" => "秒",
    "microseconds" => "秒",
    "second" => "秒",
    "seconds" => "秒",
    "minute" => "分钟",
    "minutes" => "分钟",
    "hour" => "小时",
    "hours" => "小时",
    "day" => "天",
    "days" => "天",
    "week" => "周",
    "weeks" => "周",
    "month" => "月",
    "months" => "月",
    "year" => "年",
    "years" => "年"
  }

  def time_distance(t) do
    [num, unit] =
      Timex.now()
      |> Timex.Timezone.convert(@timezone)
      |> Timex.to_erl()
      |> Timex.diff(Timex.to_erl(t), :duration)
      # credo:disable-for-next-line
      |> Timex.Format.Duration.Formatters.Humanized.format()
      |> String.split(",", trim: true)
      |> List.first()
      |> String.split(" ")

    new_unit =
      @units
      |> Map.fetch(unit)
      |> case do
        {:ok, u} -> u
        :error -> unit
      end

    "#{num}#{new_unit}前"
  end

  def format_stack(stack) do
    stack
    |> Enum.map(fn a ->
      a |> Tuple.to_list() |> List.last() |> Keyword.values() |> Enum.join(":")
    end)
  end

  def random(length \\ 20) do
    length
    |> :crypto.strong_rand_bytes()
    |> Base.url_encode64()
    |> binary_part(0, length)
  end

  @chars "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890abcdefghijklmnopqrstuvwxyz" |> String.split("")

  def random_hex(length \\ 20) do
    1..length
    |> Enum.reduce([], fn _i, acc ->
      [Enum.random(@chars) | acc]
    end)
    |> Enum.join("")
  end

  def dump_value(nil), do: %{"type" => "nil", "value" => nil}
  def dump_value(v) when is_atom(v), do: %{"type" => "atom", "value" => to_string(v)}
  def dump_value(v) when is_binary(v), do: %{"type" => "binary", "value" => v}
  def dump_value(v) when is_number(v), do: %{"type" => "number", "value" => v}

  def dump_value(v) when is_tuple(v),
    do: %{"type" => "tuple", "value" => v |> Tuple.to_list() |> Enum.map(&dump_value/1)}

  def dump_value(v) when is_list(v),
    do: %{"type" => "list", "value" => Enum.map(v, &dump_value/1)}

  def dump_value(v) when is_map(v),
    do: %{"type" => "map", "value" => Enum.map(v, &dump_value/1)}

  def load_value(%{"type" => "nil", "value" => _}), do: nil
  def load_value(%{"type" => "atom", "value" => v}), do: String.to_atom(v)
  def load_value(%{"type" => "binary", "value" => v}), do: v
  def load_value(%{"type" => "number", "value" => v}), do: v
  def load_value(%{"type" => "list", "value" => v}), do: Enum.map(v, &load_value/1)

  def load_value(%{"type" => "tuple", "value" => v}),
    do: v |> Enum.map(&load_value/1) |> List.to_tuple()

  def load_value(%{"type" => "map", "value" => v}), do: Enum.into(v, %{}, &load_value/1)

  def inspect_error(%KeyError{key: key}), do: "KeyError: #{key}"
  def inspect_error(%CompileError{description: message}), do: message
  def inspect_error(%RuntimeError{message: message}), do: message
  def inspect_error(%DBConnection.EncodeError{message: message}), do: "DBEncodeError: #{message}"

  def inspect_error(%UndefinedFunctionError{module: module, function: function, arity: arity}),
    do: "UndefinedFunctionError: #{module |> inspect}.#{function}/#{arity}"

  def inspect_error(%FunctionClauseError{module: module, function: function, arity: arity}),
    do: "FunctionClauseError: #{module |> inspect}.#{function}/#{arity}"

  def inspect_error(%Ecto.Changeset{errors: [_ | _] = errors, valid?: false}) do
    "Changeset #{inspect(errors)}"
  end

  def inspect_error(e) when is_binary(e), do: e
  def inspect_error(e) when is_atom(e), do: Atom.to_string(e)
  def inspect_error(e) when is_struct(e), do: Exception.message(e)

  def inspect_binary(v, options \\ [])
  def inspect_binary(v, _) when is_binary(v), do: v
  def inspect_binary(v, options), do: inspect(v, options)
end
