defmodule EpiContactsWeb.PageViewTest do
  use ExUnit.Case, async: true

  alias EpiContactsWeb.PageView, as: View

  describe "contact_blurb/0" do
    test "returns tel and web link" do
      html = View.contact_blurb() |> Phoenix.HTML.safe_to_string()

      assert html =~ "www.ny.gov/coronavirus"
      assert html =~ "833-227-5045"
      assert html |> Floki.parse_fragment!() |> Floki.find(~s{a[href^="tel"]})
    end
  end
end
