defmodule EpiContacts.DataCase do
  @moduledoc """
  This module defines the setup for tests requiring
  access to the application's data layer.

  You may define functions here to be used as helpers in
  your tests.

  Finally, if the test case interacts with the database,
  we enable the SQL sandbox, so changes done to the database
  are reverted at the end of every test. If you are using
  PostgreSQL, you can even run database tests asynchronously
  by setting `use EpiContacts.DataCase, async: true`, although
  this option is not recommended for other databases.
  """

  use ExUnit.CaseTemplate

  alias Ecto.Adapters.SQL.Sandbox

  using do
    quote do
      alias EpiContacts.Repo

      import Ecto
      import Ecto.Changeset
      import Ecto.Query
      import EpiContacts.DataCase

      use Oban.Testing, repo: EpiContacts.Repo

      import Euclid.Assertions
    end
  end

  setup tags do
    :ok = Sandbox.checkout(EpiContacts.Repo)

    unless tags[:async] do
      Sandbox.mode(EpiContacts.Repo, {:shared, self()})
    end

    :ok
  end

  def errors_on(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {message, opts} ->
      Regex.replace(~r"%{(\w+)}", message, fn _, key ->
        opts |> Keyword.get(String.to_existing_atom(key), key) |> to_string()
      end)
    end)
  end
end
