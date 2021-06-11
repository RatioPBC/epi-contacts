defmodule EpiContactsWeb.Assertions.ContactList do
  @moduledoc """
  Acceptance assertion helper for interacting with the contact list step of the questionnaire
  """

  use EpiContactsWeb.AcceptanceAssertions

  alias EpiContactsWeb.Assertions.AddContact

  def assert_on_contact_list_page(session, expected_contacts: []) do
    assert_has(session, css("p", text: "You have not added any contacts."))
    session
  end

  def assert_on_contact_list_page(session, expected_contacts: expected_contacts) do
    # What's a better way to do this Wallaby css query so that it returns all elements (without using count:)
    contacts = session |> find(css(".contact", count: length(expected_contacts)))
    number_of_contacts = if is_list(contacts), do: length(contacts), else: 1
    assert number_of_contacts == length(expected_contacts)
    Enum.each(expected_contacts, &assert_contact(session, &1))
    session
  end

  def delete_contacts(session, contacts_to_delete: contacts_to_delete) do
    contacts_to_delete
    |> Enum.reduce(session, fn contact, session_acc ->
      session_acc
      |> click(xpath("//*[@class=\"delete\" and ancestor::#{xpath_for_contact_with_name(contact)}"))
    end)
  end

  def click_back(session) do
    session
    |> click(css("#go-back-button"))
  end

  defp assert_contact(session, contact) do
    session
    |> assert_has(
      xpath(
        ~s|//*[@class="contact-phone" and normalize-space()="#{AddContact.contact_phone(contact)}" and ancestor::#{
          xpath_for_contact_with_name(contact)
        }|
      )
    )
    |> assert_has(
      xpath(
        ~s|//*[@class="contact-email" and normalize-space()="#{AddContact.contact_email(contact)}" and ancestor::#{
          xpath_for_contact_with_name(contact)
        }|
      )
    )
  end

  defp xpath_for_contact_with_name([first_name, last_name]),
    do: xpath_for_contact_with_name("#{first_name} #{last_name}")

  defp xpath_for_contact_with_name(contact) do
    ~s|*[@class="contact"]//*[@class="contact-name" and normalize-space()="#{AddContact.contact_name(contact)}"]]|
  end
end
