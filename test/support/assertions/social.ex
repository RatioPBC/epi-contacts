defmodule EpiContactsWeb.Assertions.Social do
  @moduledoc """
  Acceptance assertion helper for interacting with the social step of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  def assert_on_social_page(session, start_date: start_date, end_date: end_date) do
    start_date = start_date |> Timex.format!("%A, %B %d", :strftime)
    end_date = end_date |> Timex.format!("%A, %B %d", :strftime)

    session
    |> assert_has(css(".question", text: "Question 2 of 2"))
    |> assert_has(css("[data-tid=start-date]", text: start_date))
    |> assert_has(css("[data-tid=end-date]", text: end_date))
    |> assert_has(css("h1", text: "Who else have you seen from"))
  end
end
