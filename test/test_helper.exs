ExUnit.start(capture_log: true)
Ecto.Adapters.SQL.Sandbox.mode(EpiContacts.Repo, :manual)
{:ok, _} = Application.ensure_all_started(:wallaby)
Application.put_env(:wallaby, :base_url, EpiContactsWeb.Endpoint.url())
