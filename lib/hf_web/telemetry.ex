defmodule HfWeb.Telemetry do
  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  # https://hexdocs.pm/phoenix_live_dashboard/metrics.html
  def metrics do
    [
      summary("hf.http.request.duration",
        tags: [:custom],
        unit: {:native, :millisecond}
      ),
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("hf.repo.query.total_time", unit: {:native, :millisecond}),
      summary("hf.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("hf.repo.query.query_time", unit: {:native, :millisecond}),
      summary("hf.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("hf.repo.query.idle_time", unit: {:native, :millisecond}),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {HfWeb, :count_users, []}
    ]
  end
end
