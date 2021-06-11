defmodule EpiContactsWeb.Assertions.Prep do
  @moduledoc """
  Acceptance assertion helper for interacting with the prep step of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  def assert_on_prep_page(session) do
    session |> assert_has(css("h2", text: "Now, you'll be asked to add contacts you've seen from"))
  end
end
