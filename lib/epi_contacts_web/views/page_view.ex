defmodule EpiContactsWeb.PageView do
  use EpiContactsWeb, :view
  alias EpiContacts.PatientCase

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

  def formatted_release_from_isolation_date(patient_case, opts \\ []) do
    locale = opts[:locale] || get_locale() || default_locale()

    {:ok, date} =
      patient_case
      |> PatientCase.release_from_isolation_date(opts)
      |> Timex.lformat("%B %d", locale, :strftime)

    date
  end

  def self_isolate_blurb(patient_case) do
    release_from_isolation_date = formatted_release_from_isolation_date(patient_case)
    release_extra_from_isolation_date = formatted_release_from_isolation_date(patient_case, shift_days: 6)
    followed_by_text = gettext("followed by 5 days of wearing a well-fitting mask when around others")
    if_extra_text = gettext("if you are immunocompromised, or unable to wear a well-fitting mask, isolate until")
    or_text = gettext("OR")
    self_isolate_text = gettext("Self-isolate...")
    please_visit_text = gettext("Please visit the CDC website")

    assigns = %{
      followed_by_text: followed_by_text,
      if_extra_text: if_extra_text,
      or_text: or_text,
      please_visit_text: please_visit_text,
      release_extra_from_isolation_date: release_extra_from_isolation_date,
      release_from_isolation_date: release_from_isolation_date,
      self_isolate_text: self_isolate_text,
      web_link: isolation_guidance_web_link()
    }

    ~H"""
    <p>
      <span class="self-isolate-text"><%= @self_isolate_text %></span>
      <span class="self-isolate-date end-of-isolation-period"><%= @release_from_isolation_date %></span>
      <span class="followed-by-text"><%= @followed_by_text %></span>
      <span class="or-text"><strong><%= @or_text %></strong></span>
      <span class="if-extra-text"><%= @if_extra_text %></span>
      <span class="self-isolate-extra-date end-of-isolation-period"><%= @release_extra_from_isolation_date %></span>.
    </p>
    <p class="please-visit-text"><%= @please_visit_text %> <%= link(@web_link, to: @web_link, class: "please-visit-link") %></p>
    """
  end

  def more_info_web_link do
    case EpiContacts.Gettext.get_locale() do
      "es" -> "https://espanol.cdc.gov/coronavirus/2019-ncov/prevent-getting-sick/index.html"
      _ -> "https://www.cdc.gov/coronavirus/2019-ncov/prevent-getting-sick/"
    end
  end

  def isolation_guidance_web_link do
    case EpiContacts.Gettext.get_locale() do
      "es" -> "https://espanol.cdc.gov/coronavirus/2019-ncov/your-health/quarantine-isolation.html"
      _ -> "https://www.cdc.gov/coronavirus/2019-ncov/your-health/quarantine-isolation.html"
    end
  end
end
