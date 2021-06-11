defmodule EpiContacts.Monitoring.AsyncAnalyticsClient do
  @moduledoc """
    Encapsulates the asynchronous mechanism for making HTTP calls to
    PostHog so that the caller is not blocked when capturing events
  """
  alias Euclid.Exists
  alias EpiContacts.Monitoring.AnalyticsClientBehaviour
  require Logger

  @behaviour AnalyticsClientBehaviour

  @impl AnalyticsClientBehaviour
  def configuration_present?,
    do:
      Application.get_env(:posthog, :api_key) |> Exists.present?() &&
        Application.get_env(:posthog, :api_url) |> Exists.present?()

  @impl AnalyticsClientBehaviour
  def capture(event_name, metadata, timestamp) do
    # raise if config missing
    Task.start(fn ->
      analytics_client().capture(event_name, metadata, timestamp)
      |> case do
        {:ok, _} ->
          :ok

        {:error, %{status: status, body: body}} ->
          Logger.warn("Error response from PostHog: status: #{status}, body: #{inspect(body)}")
          :error

        {:error, response} ->
          Logger.warn("Error response from PostHog: #{inspect(response)}")
          :error
      end
    end)

    :ok
  end

  defp analytics_client do
    Application.get_env(:epi_contacts, :posthog_client)
  end
end
