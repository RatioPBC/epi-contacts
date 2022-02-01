defmodule EpiContactsWeb.Plugs.Locale do
  @moduledoc """
  Redirects the user to the locale picker page if locale is not specifically set.
  """

  import Phoenix.Controller, only: [redirect: 2]
  import Plug.Conn

  alias EpiContactsWeb.Router.Helpers, as: Routes

  @supported_locales EpiContacts.Gettext.known_locales()

  def init(opts \\ []), do: opts

  def call(conn, _opts) do
    locale = get_session(conn, :locale)

    if supported?(locale) do
      EpiContacts.Gettext.put_locale(locale)
      conn
    else
      redirect_to_locale_page(conn)
    end
  end

  defp supported?(locale) when locale in @supported_locales, do: true
  defp supported?(_), do: false

  defp redirect_to_locale_page(conn) do
    query = if conn.query_string == "", do: nil, else: conn.query_string
    redirect_path = %URI{path: conn.request_path, query: query} |> URI.to_string()
    locale_path = Routes.page_path(conn, :locale, redirect_to: redirect_path)

    conn
    |> redirect(to: locale_path)
    |> halt()
  end
end
