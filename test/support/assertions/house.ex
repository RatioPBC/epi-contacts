defmodule EpiContactsWeb.Assertions.House do
  @moduledoc """
  Acceptance assertion helper for interacting with the house step of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  def assert_on_house_page(session) do
    session
    |> assert_has(css(".question", text: "Question 1 of 2"))
    |> assert_has(css("h1", text: "Who has been in your house with you from"))
  end
end
