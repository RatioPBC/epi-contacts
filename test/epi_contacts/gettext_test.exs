defmodule EpiContacts.GettextTest do
  use ExUnit.Case, async: true

  alias EpiContacts.Gettext

  test "put_locale/1" do
    original_locale = Gettext.get_locale()
    Gettext.put_locale("es")
    assert original_locale != Gettext.get_locale()
  end
end
