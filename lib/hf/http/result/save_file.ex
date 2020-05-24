defmodule Hf.Http.Result.SaveFile do
  use Hf.Http.Middleware

  @download_directory "target"

  def pipe(
        %Api{state: :ok, source: source, resp: %Resp{request_url: url}} = a,
        %{save_file: %{target: [_ | _] = target}} = input
      ) do
    obj = get_in(a, Enum.map(target, &Access.key/1))

    {name, ext} =
      url
      |> URI.decode()
      |> URI.parse()
      |> Map.fetch!(:path)
      |> Kernel.||("")
      |> String.split("/")
      |> List.last()
      |> Kernel.||("")
      |> String.split(".")
      |> case do
        [a, b | _] -> {a, b}
        [a] -> {a, ""}
      end

    path = name || input[:save_name] || generate_name(a)

    new_path =
      if path |> String.ends_with?(ext) do
        path
      else
        path <> "." <> ext
      end

    full_path =
      Path.join([
        @download_directory,
        source |> Tool.api_name() |> Atom.to_string(),
        Util.now(:date),
        new_path
      ])

    full_path
    |> write(obj, [:write, :exclusive])
    |> case do
      :ok -> {:ok, full_path}
      {:error, reason} -> {:error, {reason, full_path}}
    end
  end

  defp generate_name(%Api{rid: id}), do: "id_#{id}"
  defp generate_name(_), do: Util.random_hex()

  defp write(path, body, modes) do
    path
    |> Path.dirname()
    |> File.mkdir_p!()

    path
    |> File.open(modes)
    |> case do
      {:ok, file} ->
        IO.binwrite(file, body)
        File.close(file)
        :ok

      {:error, reason} ->
        {:error, reason}
    end
  end
end
