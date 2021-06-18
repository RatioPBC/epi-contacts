defmodule EpiContacts.Gettext do
  @moduledoc """
  A module providing Internationalization with a gettext-based API.

  By using [Gettext](https://hexdocs.pm/gettext),
  your module gains a set of macros for translations, for example:

      import EpiContacts.Gettext

      # Simple translation
      gettext("Here is the string to translate")

      # Plural translation
      ngettext("Here is the string to translate",
               "Here are the strings to translate",
               3)

      # Domain-based translation
      dgettext("errors", "Here is the error message to translate")

  See the [Gettext Docs](https://hexdocs.pm/gettext) for detailed usage.
  """
  use Gettext, otp_app: :epi_contacts

  def get_locale do
    Gettext.get_locale(__MODULE__)
  end

  def put_locale(locale) when is_binary(locale) do
    Gettext.put_locale(__MODULE__, locale)
  end
end
