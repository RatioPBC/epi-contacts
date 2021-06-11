defmodule EpiContacts.Monitoring.AsyncAnalyticsClientTest do
  use ExUnit.Case, async: false
  import Mox
  setup :verify_on_exit!

  alias EpiContacts.Monitoring.AsyncAnalyticsClient

  def set_up_success_response(caller) do
    expect(AnalyticsClientBehaviourMock, :capture, fn event_name, metadata, timestamp ->
      send(caller, {:capture_called_with_args, [event_name, metadata, timestamp]})

      {:ok,
       %{
         body: %{"status" => 1},
         headers: [
           {"Date", "Tue, 19 Jan 2021 18:19:55 GMT"},
           {"Server", "WSGIServer/0.2 CPython/3.8.7"},
           {"Content-Type", "application/json"},
           {"X-Frame-Options", "DENY"},
           {"Content-Length", "13"},
           {"Vary", "Cookie"},
           {"X-Content-Type-Options", "nosniff"}
         ],
         status: 200
       }}
    end)
  end

  describe "capture()" do
    test "it sends the event to the PostHog client" do
      set_up_success_response(self())

      event_name = "very important event"
      timestamp = DateTime.utc_now()

      metadata = %{
        some: "data"
      }

      assert :ok = AsyncAnalyticsClient.capture(event_name, metadata, timestamp)

      assert_receive({:capture_called_with_args, [^event_name, ^metadata, ^timestamp]})
    end
  end

  describe "configuration_present?" do
    setup do
      Application.delete_env(:posthog, :api_key)
      Application.delete_env(:posthog, :api_url)
    end

    test "when posthog api url and key are not present, it returns false" do
      refute AsyncAnalyticsClient.configuration_present?()
    end

    test "when only the posthog api key is present, it returns false" do
      Application.put_env(:posthog, :api_key, "TOP SECRET")
      refute AsyncAnalyticsClient.configuration_present?()
    end

    test "when only the posthog api URL is present, it returns false" do
      Application.put_env(:posthog, :api_url, "example.com")
      refute AsyncAnalyticsClient.configuration_present?()
    end

    test "when posthog api url and key are present, it returns true" do
      Application.put_env(:posthog, :api_key, "TOP SECRET")
      Application.put_env(:posthog, :api_url, "example.com")
      assert AsyncAnalyticsClient.configuration_present?()
    end
  end
end
