defmodule EpiContactsWeb.Assertions.AddContact do
  @moduledoc """
  Acceptance assertion helper for interacting with the add contact step of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  def add_contacts(session, contacts_to_add: contacts_to_add) do
    contacts_to_add
    |> Enum.reduce(session, fn [first_name, last_name], session_acc ->
      contact = first_name <> " " <> last_name

      session_acc
      |> click_button(:add_contact)
      |> fill_in_contact(
        first_name: first_name,
        last_name: last_name,
        phone: contact_phone(contact),
        email: contact_email(contact)
      )
      |> set_value(Query.checkbox("This person is under 18 years old."), is_minor_checkbox_value(contact))
      |> click_button(:submit_contact)
    end)
  end

  def fill_in_contact(session, first_name: first_name, last_name: last_name, phone: phone, email: email) do
    exposed_on = css("#contact_exposed_on")

    max =
      session
      |> Wallaby.Browser.attr(exposed_on, "max")
      |> Date.from_iso8601!()
      |> Timex.shift(days: -2)
      |> Timex.format!("%m/%d/%Y", :strftime)

    script = """
    document.getElementById("contact_exposed_on").value = "#{max}"
    """

    session
    |> set_value(css("input#contact_first_name"), first_name)
    |> set_value(css("input#contact_last_name"), last_name)
    |> set_value(css("input#contact_phone"), phone)
    |> set_value(css("input#contact_email"), email)
    |> clear(exposed_on)
    |> execute_script(script)
    |> set_value(exposed_on, max)
    |> set_value(Query.select("contact_contact_location"), "workplace")
    |> set_value(Query.select("contact_relationship"), "friend")
    |> set_value(Query.select("contact_primary_language"), "en")
  end

  def contact_name(contact) do
    to_string(contact)
  end

  def contact_phone(<<first_char::utf8>> <> _) do
    i = rem(first_char, 10)
    "+1 (#{i}#{i}#{i}) #{i}#{i}#{i}-#{i}#{i}#{i}#{i}"
  end

  def contact_phone(contact), do: contact |> to_string() |> contact_phone()

  def contact_email([first_name, last_name]), do: contact_email("#{first_name} #{last_name}")

  def contact_email(contact) do
    "#{String.replace(contact, " ", "")}@example.com"
  end

  def is_minor_checkbox_value("Minor " <> _), do: :selected
  def is_minor_checkbox_value(_), do: :unselected
end
