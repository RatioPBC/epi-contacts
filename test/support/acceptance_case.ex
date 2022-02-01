defmodule EpiContactsWeb.AcceptanceCase do
  @moduledoc """
  A case template for running acceptance tests. Pulls in wallaby helpers.
  """

  alias EpiContacts.Commcare.Client, as: CommcareClient

  use ExUnit.CaseTemplate

  using do
    quote do
      use Wallaby.DSL
      use Wallaby.Feature

      import Wallaby.Query, only: [css: 1, css: 2, button: 1, xpath: 1]
      alias Wallaby.Element
      import EpiContactsWeb.AcceptanceTestHelpers

      @endpoint EpiContactsWeb.Endpoint
      alias EpiContactsWeb.Endpoint
      @moduletag :acceptance
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(EpiContacts.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(EpiContacts.Repo, {:shared, self()})
    end

    {:ok, _} = Application.ensure_all_started(:wallaby)

    :ok
  end

  # in acceptance tests, we shouldn't mock the Commcare.Client, but instead let it call through to the HTTP layer
  setup _tags do
    Mox.stub(CommcareClientBehaviourMock, :get_case, fn domain, case_id ->
      CommcareClient.get_case(domain, case_id)
    end)

    :ok
  end
end
