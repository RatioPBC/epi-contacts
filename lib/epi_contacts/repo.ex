defmodule EpiContacts.Repo do
  use Ecto.Repo, otp_app: :epi_contacts, adapter: Ecto.Adapters.Postgres

  def init(_, opts), do: {:ok, load_system_env(opts)}

  defp load_system_env(opts) do
    hostname = System.get_env("POSTGRES_HOST", "localhost")
    database_url = System.get_env("DATABASE_SECRET", "{}") |> to_url()
    pool_size = System.get_env("POOL_SIZE", "20") |> String.to_integer()

    Keyword.merge(opts,
      hostname: hostname,
      pool_size: pool_size,
      url: database_url
    )
  end

  defp to_url("{}"), do: ""

  defp to_url(database_secret) do
    %{"username" => user, "password" => pass, "host" => host, "port" => port, "dbname" => dbname} =
      database_secret
      |> Jason.decode!()

    "ecto://#{user}:#{pass}@#{host}:#{port}/#{dbname}"
  end
end
