defmodule EpiContactsWeb.CommcareApiController do
  use EpiContactsWeb, :controller

  alias EpiContacts.CommcareSmsTrigger

  def webhook(conn, %{"domain" => _domain, "case_id" => _case_id} = params) do
    CommcareSmsTrigger.enqueue!(params)

    text(conn, "OK")
  end
end
