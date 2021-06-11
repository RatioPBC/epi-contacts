defmodule EpiContacts.Repo do
  use Ecto.Repo, otp_app: :epi_contacts, adapter: Ecto.Adapters.Postgres

  alias Vapor.Provider.Dotenv
  alias Vapor.Provider.Env

  def init(_, opts), do: {:ok, load_system_env(opts)}

  defp load_system_env(opts) do
    providers = [
      %Dotenv{},
      %Env{
        bindings: [
          {:hostname, "POSTGRES_HOST", default: "localhost"},
          {:database_url, "DATABASE_SECRET", default: "{}"},
          {:pool_size, "POOL_SIZE", default: "10"}
        ]
      }
    ]

    translations = [
      pool_size: &String.to_integer(&1),
      database_url: &to_url(&1)
    ]

    config = Vapor.load!(providers, translations)

    Keyword.merge(opts,
      hostname: config.hostname,
      pool_size: config.pool_size,
      url: config.database_url
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
