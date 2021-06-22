defmodule EpiContacts.Locations do
  @moduledoc false

  import EpiContacts.Gettext
  import EpiContacts.Utils, only: [collect_first_elements: 1]

  @spec locations() :: list(binary())
  def locations,
    do: options() |> collect_first_elements()

  @spec options() :: list({binary(), binary()})
  def options,
    do: [
      {gettext("At home (household member or friend)"), "household"},
      {gettext("At home (caretaker)"), "caretaker"},
      {gettext("Place of worship"), "church"},
      {gettext("Healthcare facility"), "health_care"},
      {gettext("Nursing/Assisted living"), "nursing_assisted_living_home"},
      {gettext("School setting"), "school_setting"},
      {gettext("Workplace"), "workplace"},
      {gettext("Other"), "other"}
    ]
end
