defmodule EpiContactsWeb.IntegrationCase do
  @moduledoc false
  use ExUnit.CaseTemplate

  using do
    quote do
      use EpiContactsWeb.ConnCase
      use PhoenixIntegration
    end
  end
end
