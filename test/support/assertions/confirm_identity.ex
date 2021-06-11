defmodule EpiContactsWeb.Assertions.ConfirmIdentity do
  @moduledoc """
  Acceptance assertion helper for interacting with the confirm identity step of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  def assert_on_confirm_identity_page(session) do
    session
    |> assert_has(css("h2", text: "Confirm your identity"))
  end

  def fill_in_incorrect_dob_and_see_error(session, incorrect_dob: incorrect_dob) do
    session
    |> set_value(css("input[type=date]"), incorrect_dob |> Timex.format!("%m/%d/%Y", :strftime))
    |> click_button(:next)
    |> assert_has(css(".invalid-feedback", text: "is not correct"))
  end

  def fill_in_correct_dob(session, dob: dob) do
    session
    |> clear(css("input[type=date]"))
    |> set_value(css("input[type=date]"), dob |> Timex.format!("%m/%d/%Y", :strftime))
  end
end
