defmodule Hf.Parser do
  def file(path) do
    with {:ok, data} <- File.read(path), do: string(data)
  end

  def string(input) do
    with {:ok, quoted} <- Code.string_to_quoted(input), do: {:ok, parse(wrap(quoted))}
  catch
    {:error, _} = error -> error
  end

  defp wrap({:__block__, _, data}), do: data
  defp wrap(data), do: [data]

  defp parse(data) when is_number(data) when is_binary(data) when is_atom(data),
    do: data

  defp parse(list) when is_list(list) do
    Enum.map(list, fn
      {k, v} -> {parse(k), parse(v)}
      other -> parse(other)
    end)
  end

  defp parse({:%{}, _, data}) do
    for {key, value} <- data, into: %{}, do: {parse(key), parse(value)}
  end

  defp parse({:{}, _, data}) do
    data
    |> Enum.map(&parse/1)
    |> List.to_tuple()
  end

  defp parse({:__aliases__, _, names}), do: Module.concat(names)

  defp parse({:sigil_W, _meta, [{:<<>>, _, [string]}, mod]}), do: word_sigil(string, mod)

  defp parse({:sigil_R, _meta, [{:<<>>, _, [string]}, mod]}),
    do: Regex.compile!(string, List.to_string(mod))

  defp parse({sigil, meta, _data} = quoted) when sigil in ~w[sigil_w sigil_r]a do
    line = Keyword.get(meta, :line)
    throw({:error, {:illegal_sigil, line, quoted}})
  end

  defp parse({_, meta, _} = quoted) do
    line = Keyword.get(meta, :line)
    throw({:error, {:invalid, line, quoted}})
  end

  defp word_sigil(string, []), do: word_sigil(string, 's')

  defp word_sigil(string, [mod]) when mod in 'sac' do
    parts = String.split(string)

    case mod do
      ?s -> parts
      ?a -> Enum.map(parts, &String.to_atom/1)
      ?c -> Enum.map(parts, &String.to_charlist/1)
    end
  end
end
