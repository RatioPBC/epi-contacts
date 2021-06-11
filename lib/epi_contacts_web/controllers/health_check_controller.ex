defmodule EpiContactsWeb.HealthCheckController do
  use EpiContactsWeb, :controller

  def index(conn, _params) do
    text(conn, "OK")
  end
end
