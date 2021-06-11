defmodule EpiContactsWeb.LayoutHelpers do
  @moduledoc """
  Provides view helpers that are used in shared layouts
  """

  alias Timex.Format.DateTime.Formatters.Strftime

  def revision_month_and_year do
    Application.get_env(:epi_contacts, :revision_date_epoch_seconds)
    |> String.to_integer()
    |> DateTime.from_unix!()
    |> Strftime.format!("%B %Y")
  rescue
    date_format_exception ->
      Sentry.capture_exception(date_format_exception, stacktrace: __STACKTRACE__)
      "Unknown"
  end
end
