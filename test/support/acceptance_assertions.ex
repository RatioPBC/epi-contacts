defmodule EpiContactsWeb.AcceptanceAssertions do
  @moduledoc """
  `use` this to get all the acceptance assertion helpers
  """

  defmacro __using__(_opts \\ []) do
    quote do
      use Wallaby.DSL
      import Wallaby.Query, only: [css: 1, css: 2, button: 1, xpath: 1]

      import ExUnit.Assertions
      import EpiContactsWeb.AcceptanceTestHelpers

      alias EpiContactsWeb.Endpoint
      alias EpiContactsWeb.Router.Helpers, as: Routes
    end
  end
end
