defmodule EpiContactsWeb.LayoutHelpers do
  @moduledoc """
  Provides view helpers that are used in shared layouts
  """

  import EpiContacts.Gettext

  def revision_month_and_year(opts \\ []) do
    with {:ok, seconds} <- revision_date_epoch_seconds(opts[:revision]),
         {:ok, dt} <- DateTime.from_unix(seconds),
         {:ok, time} <- Timex.format(dt, "%B %Y", :strftime) do
      time
    else
      {:error, error} ->
        capture_message_and_return_unknown(error, opts)
    end
  end

  defp capture_message_and_return_unknown(message, opts) do
    result = opts[:sentry_result] || :async

    Sentry.capture_message(to_string(message),
      extra: %{revision_date_epoch_seconds: revision_date_epoch_seconds_value()},
      result: result
    )

    gettext("Unknown")
  end

  defp revision_date_epoch_seconds_value do
    Application.get_env(:epi_contacts, :revision_date_epoch_seconds)
  end

  defp revision_date_epoch_seconds(s) when is_binary(s),
    do: {:ok, String.to_integer(s)}

  defp revision_date_epoch_seconds(s) when is_integer(s),
    do: {:ok, s}

  defp revision_date_epoch_seconds(nil) do
    case revision_date_epoch_seconds_value() do
      nil -> {:error, :revision_date_epoch_seconds_missing}
      "" -> {:error, :revision_date_epoch_seconds_empty}
      s -> {:ok, String.to_integer(s)}
    end
  end
end
