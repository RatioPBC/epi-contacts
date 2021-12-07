defmodule EpiContactsWeb.PageView do
  use EpiContactsWeb, :view

  def contact_blurb do
    url = "https://www.ny.gov/coronavirus"
    web_link = link(url, to: url)
    tel_link = link("(833) 227-5045", to: "tel:1-833-227-5045")

    text =
      gettext("If you have any questions, please contact us...",
        phone_number: safe_to_string(tel_link),
        web_link: safe_to_string(web_link)
      )
      |> raw()

    assigns = %{text: text}

    ~H"""
    <p><%= @text %></p>
    """
  end

  def protect_your_family_blurb do
    url = more_info_web_link()
    web_link = link(url, to: url)

    text =
      gettext("Protect your family and the other people you live with by...", web_link: safe_to_string(web_link))
      |> raw()

    assigns = %{text: text}

    ~H"""
    <p><%= @text %></p>
    """
  end

  def more_info_web_link do
    case EpiContacts.Gettext.get_locale() do
      "es" -> "https://espanol.cdc.gov/coronavirus/2019-ncov/prevent-getting-sick/index.html"
      _ -> "https://www.cdc.gov/coronavirus/2019-ncov/prevent-getting-sick/"
    end
  end
end
