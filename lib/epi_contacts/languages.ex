defmodule EpiContacts.Languages do
  @moduledoc false

  import EpiContacts.Gettext
  import EpiContacts.Utils

  @spec languages() :: list(binary())
  def languages, do: options() |> collect_first_elements()

  @spec values() :: list(binary())
  def values, do: options() |> collect_second_elements()

  @spec options() :: list({binary(), binary()})
  def options,
    do: [
      {gettext("English"), "en"},
      {gettext("Spanish"), "es"},
      {gettext("Chinese Cantonese"), "chinese_cantonese"},
      {gettext("Chinese Mandarin"), "chinese_mandarin"},
      {gettext("Russian"), "ru"},
      {gettext("Haitian Creole"), "haitian_creole"},
      {gettext("Hebrew"), "hebrew"},
      {gettext("Hindi"), "hindi"},
      {gettext("Bengali"), "bengali"},
      {gettext("Korean"), "korean"},
      {gettext("Arabic"), "arabic"},
      {gettext("France"), "fra"},
      {gettext("Italian"), "italian"},
      {gettext("Yiddish"), "yiddish"},
      {gettext("Polish"), "polish"},
      {gettext("Swahili"), "swahili"},
      {gettext("Other"), "other"}
    ]
end
