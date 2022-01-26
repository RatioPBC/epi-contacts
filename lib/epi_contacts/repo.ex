defmodule EpiContacts.Repo do
  use Ecto.Repo, otp_app: :epi_contacts, adapter: Ecto.Adapters.Postgres

  def init(_, opts), do: {:ok, load_system_env(opts)}

  defp load_system_env(opts) do
    Keyword.merge(opts,
      hostname: System.get_env("POSTGRES_HOST", "localhost"),
      url: database_url()
    )
  end

  defp decode_database_secret_from_json(nil), do: ""

  defp decode_database_secret_from_json(database_secret) when is_binary(database_secret) do
    %{
      "username" => user,
      "password" => pass,
      "host" => host,
      "port" => port,
      "dbname" => dbname
    } = Jason.decode!(database_secret)

    "ecto://#{user}:#{pass}@#{host}:#{port}/#{dbname}"
  end

  defp connection_info do
    Application.get_env(:epi_contacts, __MODULE__)[:connection_info]
  end

  defp database_url do
    connection_info()
    |> decode_database_secret_from_json()
  end
end
