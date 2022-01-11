defmodule EpiContactsWeb.PageViewTest do
  use ExUnit.Case, async: true

  alias EpiContactsWeb.PageView, as: View
  alias Phoenix.HTML.Safe

  def safe_to_html(safe) do
    safe
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_fragment!()
  end

  describe "contact_blurb/0" do
    test "returns tel and web link" do
      html = View.contact_blurb() |> Safe.to_iodata() |> IO.iodata_to_binary()

      assert html =~ "www.ny.gov/coronavirus"
      assert html =~ "833-227-5045"
      assert html =~ "If you have any questions, please contact us"
      assert html |> Floki.parse_fragment!() |> Floki.find(~s{a[href^="tel"]})
    end
  end

  describe "protect_your_family_blurb/0" do
    test "returns web link in content" do
      html = View.protect_your_family_blurb() |> Safe.to_iodata() |> IO.iodata_to_binary()
      link = View.more_info_web_link()

      assert html =~ "Protect your family"
      a = html |> Floki.parse_fragment!() |> Floki.find("a")
      assert Floki.attribute(a, "href") == [link]
      assert Floki.text(a) == link
    end
  end

  describe "self_isolate_blurb/1" do
    test "returns self isolation guidance" do
      patient_case = %{
        "properties" => %{
          "isolation_start_date" => "2021-10-10"
        }
      }

      html = patient_case |> View.self_isolate_blurb() |> safe_to_html()
      self_isolate_date = Floki.find(html, ".self-isolate-date")
      assert Floki.text(self_isolate_date) =~ "October 16"
      extra_self_isolate_date = Floki.find(html, ".self-isolate-extra-date")
      assert Floki.text(extra_self_isolate_date) =~ "October 21"
      please_visit_link = Floki.find(html, ".please-visit-link")
      assert Floki.text(please_visit_link) == View.isolation_guidance_web_link()
      assert Floki.attribute(please_visit_link, "href") == [View.isolation_guidance_web_link()]
    end
  end

  describe "more_info_web_link/0" do
    setup context do
      if locale = context[:locale], do: EpiContacts.Gettext.put_locale(locale)
      :ok
    end

    @tag locale: "es"
    test "returns Spanish link" do
      assert View.more_info_web_link() ==
               "https://espanol.cdc.gov/coronavirus/2019-ncov/prevent-getting-sick/index.html"
    end

    test "retuns the English link" do
      assert View.more_info_web_link() ==
               "https://www.cdc.gov/coronavirus/2019-ncov/prevent-getting-sick/"
    end
  end

  describe "isolation_guidance_web_link/0" do
    setup context do
      if locale = context[:locale], do: EpiContacts.Gettext.put_locale(locale)
      :ok
    end

    @tag locale: "es"
    test "returns Spanish link" do
      assert View.isolation_guidance_web_link() ==
               "https://espanol.cdc.gov/coronavirus/2019-ncov/your-health/quarantine-isolation.html"
    end

    test "retuns the English link" do
      assert View.isolation_guidance_web_link() ==
               "https://www.cdc.gov/coronavirus/2019-ncov/your-health/quarantine-isolation.html"
    end
  end
end
