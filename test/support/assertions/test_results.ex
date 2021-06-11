defmodule EpiContactsWeb.Assertions.TestResults do
  @moduledoc """
  Acceptance assertion helper for interacting with the test results step of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  def assert_on_test_results_page(session, name: name) do
    session
    |> assert_has(css("p", text: "Dear #{name},"))
  end

  def assert_contact(session, initials, last_4_of_phone_number) do
    session
    |> assert_has(css("td", text: initials))
    |> assert_has(css("td", text: last_4_of_phone_number))
  end
end
