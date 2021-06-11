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

    content_tag(:p, text)
  end
end
