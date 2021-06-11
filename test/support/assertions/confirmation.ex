defmodule EpiContactsWeb.Assertions.Confirmation do
  @moduledoc """
  Acceptance assertion helper for interacting with the confirmation step of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  def assert_on_confirmation_page(session) do
    session |> assert_has(css("h2", text: "Thank you for helping us stop the spread of COVID-19."))
  end

  def assert_end_of_isolation_date_on_confirmation_page(session, expected_end_of_isolation_date) do
    session |> assert_has(css("span", text: expected_end_of_isolation_date |> Timex.format!("%B %d", :strftime)))
  end
end
