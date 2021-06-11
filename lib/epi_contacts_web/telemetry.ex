defmodule EpiContactsWeb.Telemetry do
  @moduledoc """
  Supervisor for telemetry listeners/reporters
  """

  use Supervisor
  import Telemetry.Metrics

  def start_link(arg) do
    Supervisor.start_link(__MODULE__, arg, name: __MODULE__)
  end

  @impl true
  def init(_arg) do
    children = [
      {:telemetry_poller, measurements: periodic_measurements(), period: 10_000}
      # Add reporters as children of your supervision tree.
      # {Telemetry.Metrics.ConsoleReporter, metrics: metrics()}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end

  def metrics do
    [
      # Phoenix Metrics
      summary("phoenix.endpoint.stop.duration",
        unit: {:native, :millisecond}
      ),
      summary("phoenix.router_dispatch.stop.duration",
        tags: [:route],
        unit: {:native, :millisecond}
      ),

      # Database Metrics
      summary("share_my_contacts.repo.query.total_time", unit: {:native, :millisecond}),
      summary("share_my_contacts.repo.query.decode_time", unit: {:native, :millisecond}),
      summary("share_my_contacts.repo.query.query_time", unit: {:native, :millisecond}),
      summary("share_my_contacts.repo.query.queue_time", unit: {:native, :millisecond}),
      summary("share_my_contacts.repo.query.idle_time", unit: {:native, :millisecond}),

      # VM Metrics
      summary("vm.memory.total", unit: {:byte, :kilobyte}),
      summary("vm.total_run_queue_lengths.total"),
      summary("vm.total_run_queue_lengths.cpu"),
      summary("vm.total_run_queue_lengths.io"),

      # Page Visit Metrics
      counter("share_my_contacts.analytics.page_visit.confirm_identity_page"),
      counter("share_my_contacts.analytics.page_visit.test_results_page")
    ]
  end

  defp periodic_measurements do
    [
      # A module, function and arguments to be invoked periodically.
      # This function must call :telemetry.execute/3 and a metric must be added above.
      # {EpiContactsWeb, :count_users, []}
    ]
  end
end
