defmodule EpiContactsWeb.Plugs.CommcareInfoLoader do
  @moduledoc """
  Pulls the CommCare case_id and domain out of the URL or secure ID.
  """

  require Logger

  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  alias EpiContactsWeb.Router.Helpers, as: Routes

  def init(opts \\ []), do: opts

  def call(%{params: %{"case_id" => case_id, "commcare_domain" => domain}} = conn, _opts) do
    put_info_on_session(conn, case_id, domain)
  end

  def call(%{params: %{"secure_id" => secure_id}} = conn, _opts) do
    case EpiContacts.SecureId.decode(secure_id) do
      {:ok, %{"d" => domain, "c" => case_id} = data} ->
        put_txn_id_on_logger(data)
        Logger.info("decoded_secure_id")

        put_info_on_session(conn, case_id, domain)

      _ ->
        Logger.error("error_decoding_secure_id", %{secure_id: secure_id})
        halt_and_redirect(conn, :link_expired)
    end
  end

  def call(conn, _opts) do
    halt_and_redirect(conn, :error)
  end

  defp halt_and_redirect(conn, action) do
    conn
    |> clear_session()
    |> redirect(to: Routes.page_path(conn, action))
    |> halt()
  end

  defp put_txn_id_on_logger(%{"txn_id" => txn_id}), do: Logger.metadata(sms_trigger_txn_id: txn_id)
  defp put_txn_id_on_logger(_), do: :ok

  defp put_info_on_session(conn, case_id, domain) do
    Logger.metadata(commcare_case_id: case_id, commcare_domain: domain)

    conn
    |> put_session(:case_id, case_id)
    |> put_session(:domain, domain)
  end
end
