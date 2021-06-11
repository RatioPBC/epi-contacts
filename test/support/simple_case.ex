defmodule EpiContacts.Test.SimpleCase do
  @moduledoc """
    test case type for including Euclid assertions etc
  """
  use ExUnit.CaseTemplate

  using do
    quote do
      import Euclid.Test.Extra.Assertions
    end
  end
end
