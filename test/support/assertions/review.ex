defmodule EpiContactsWeb.Assertions.Review do
  @moduledoc """
  Acceptance assertion helper for interacting with the review step of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  def assert_on_review_page(session) do
    session
    |> assert_has(css("h2", text: "Review your contacts"))
  end

  def assert_error_on_i_agree_checkbox(session) do
    session
    |> assert_has(css(".invalid-feedback", text: "must be accepted"))
  end

  def check_i_agree_checkbox(session) do
    session
    |> click(Query.checkbox("I agree"))
  end
end
