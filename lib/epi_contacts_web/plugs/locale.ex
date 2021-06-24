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

    if supported?(locale),
      do: conn,
      else: conn |> redirect(to: Routes.page_path(conn, :locale)) |> halt()
  end

  defp supported?(locale) when locale in @supported_locales, do: true
  defp supported?(_), do: false
end
