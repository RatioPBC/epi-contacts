defmodule EpiContactsWeb.Assertions.Error do
  @moduledoc """
  Acceptance assertion helper for interacting with the error state of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  def assert_on_error_page(session) do
    session |> assert_has(css("h1", text: "We're sorry, but something went wrong"))
  end
end
