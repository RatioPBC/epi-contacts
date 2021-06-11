defmodule EpiContactsWeb.ErrorViewTest do
  use EpiContactsWeb.ConnCase, async: true

  # Bring render/3 and render_to_string/3 for testing custom views
  import Phoenix.View

  test "renders 404.html", %{conn: conn} do
    assert render_to_string(EpiContactsWeb.ErrorView, "404.html", conn: conn) =~ "that page cannot be found"
  end

  test "renders 500.html", %{conn: conn} do
    assert render_to_string(EpiContactsWeb.ErrorView, "500.html", conn: conn) =~ "that page cannot be loaded"
  end
end
