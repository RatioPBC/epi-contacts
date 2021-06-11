defmodule EpiContactsWeb.Plugs.ContentSecurityPolicyHeader do
  @moduledoc """
  Sets the content security policy so that it it sufficiently restrictive while also allowing websocket connections.

  Using this plug will allow websocket connections to the configured endpoint.
  """

  import Plug.Conn

  alias Euclid.Extra.Random

  def init(opts \\ []), do: opts

  def call(conn, header_override: header_override) do
    conn
    |> add_nonce()
    |> put_resp_header("content-security-policy", header_override)
  end

  def call(conn, _opts) do
    conn
    |> add_nonce()
    |> add_csp()
  end

  defp add_csp(conn) do
    put_resp_header(conn, "content-security-policy", csp(conn))
  end

  defp add_nonce(conn) do
    put_private(conn, :nonce, Random.string())
  end

  defp csp(conn) do
    nonce = conn.private[:nonce]

    "default-src 'self'; \
    img-src 'self' 'nonce-#{nonce}' 'unsafe-inline'; \
    style-src 'self' 'nonce-#{nonce}' 'unsafe-inline'; \
    connect-src 'self' #{url_for(conn, "ws")} #{url_for(conn, "wss")}; \
    frame-ancestors 'none'"
  end

  defp url_for(conn, scheme) do
    Phoenix.Controller.endpoint_module(conn).struct_url
    |> Map.put(:scheme, scheme)
    |> Map.put(:port, nil)
    |> URI.to_string()
  end
end
