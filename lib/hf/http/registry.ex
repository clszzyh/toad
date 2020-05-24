defmodule Hf.Http.Registry do
  use Hf.Http.Common

  use GenServer

  @derive [{Inspect, except: [:metas]}]
  defstruct apis: %{}, versions: %{}, metas: %{}, count: 0, errors: %{}

  def start_link(_) do
    GenServer.start_link(__MODULE__, nil, name: __MODULE__)
  end

  def init(_) do
    {:ok, %__MODULE__{}}
  end

  def register(o), do: GenServer.cast(__MODULE__, {:register, o})
  def state, do: GenServer.call(__MODULE__, :state)
  def module(n), do: GenServer.call(__MODULE__, {:module, n})
  def name(n), do: GenServer.call(__MODULE__, {:name, n})
  def versions(n), do: GenServer.call(__MODULE__, {:versions, n})

  def handle_call({:versions, n}, _, %__MODULE__{versions: %{} = versions} = state)
      when is_atom(n) do
    {:reply, Map.get(versions, n, %{}), state}
  end

  def handle_call({:name, n}, _, %__MODULE__{apis: %{} = apis} = state) do
    result =
      apis
      |> Map.get(n, {nil, nil, nil, nil})
      |> elem(3)

    {:reply, result, state}
  end

  def handle_call(:state, _from, state), do: {:reply, state, state}

  def handle_call({:module, {name, version}}, from, %__MODULE__{} = state) when is_binary(name) do
    handle_call({:module, {String.to_atom(name), version}}, from, %__MODULE__{} = state)
  end

  def handle_call({:module, {name, 0}}, from, %__MODULE__{} = state) when is_atom(name) do
    handle_call({:module, name}, from, state)
  end

  def handle_call({:module, {name, version}}, _, %__MODULE__{versions: versions} = state)
      when is_atom(name) and is_integer(version) do
    result = versions |> Map.get(name, %{}) |> Map.get(version)
    {:reply, result, state}
  end

  def handle_call({:module, name}, from, %__MODULE__{} = state) when is_binary(name) do
    handle_call({:module, String.to_atom(name)}, from, %__MODULE__{} = state)
  end

  def handle_call({:module, name}, from, %__MODULE__{versions: versions} = state)
      when is_atom(name) do
    versions
    |> Map.get(name, %{nil: nil})
    |> Enum.sort_by(fn {v, _} -> v end, :desc)
    |> List.first()
    |> elem(1)
    |> case do
      nil ->
        name
        |> to_string
        |> String.split("_")
        |> List.last()
        |> case do
          "v" <> v ->
            handle_call(
              {:module,
               {String.replace_trailing(Atom.to_string(name), "_v#{v}", ""), String.to_integer(v)}},
              from,
              state
            )

          _ ->
            {:reply, nil, state}
        end

      module ->
        {:reply, module, state}
    end
  end

  def handle_cast(
        {:register, {:error, {{id, name, version}, err}}},
        %__MODULE__{errors: %{} = errors} = state
      ) do
    use(Hf.ReportError, Util.inspect_error(err))
    {:noreply, %__MODULE__{state | errors: errors |> Map.put({id, name, version}, err)}}
  end

  def handle_cast(
        {:register, {:ok, {{id, name, version}, module}}},
        %__MODULE__{count: count, apis: %{} = apis, versions: %{} = versions, metas: %{} = metas} =
          state
      ) do
    info([count, {:id, id}, name, version, module])

    new_version =
      versions
      |> Map.get(name)
      |> case do
        nil -> %{version => module}
        %{} = m -> Map.put(m, version, module)
      end

    {:noreply,
     %__MODULE__{
       state
       | count: count + 1,
         apis:
           Map.put(apis, module, {id, name, version, "#{name}_v#{version}" |> String.to_atom()}),
         metas: Map.put(metas, module, module.meta),
         versions: Map.put(versions, name, new_version)
     }}
  end
end
