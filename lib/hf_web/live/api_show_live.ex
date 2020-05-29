defmodule HfWeb.ApiShowLive do
  use HfWeb.LiveView

  def render(assigns) do
    ~L"""
    """
  end

  def mount(%{"id" => job_id}, _session, socket) do
    if connected?(socket), do: Hf.subscribe_api(job_id)
    {:ok, assign(socket, :job, Domain.fetch_job!(job_id))}
  end

  def handle_info({:trace, obj}, socket) do
    {:noreply,
     update(socket, :job, fn %J{api: %Api{trace: trace} = a} = j ->
       %J{j | api: %Api{a | trace: [obj | trace]}}
     end)}
  end

  def handle_info({:insert_persist, %{} = changes}, socket) do
    {:noreply,
     update(socket, :job, fn
       %J{req: nil} = j ->
         %J{j | req: struct(R, changes)}

       j ->
         j
     end)}
  end

  def handle_info({:update_persist, %{} = changes}, socket) do
    {:noreply,
     update(socket, :job, fn %J{req: %R{} = r} = j ->
       %J{j | req: r |> Map.merge(changes)}
     end)}
  end
end
