defmodule EpiContacts.Relationships do
  @moduledoc false

  import EpiContacts.Gettext
  import EpiContacts.Utils

  @spec relationships() :: list(binary())
  def relationships, do: options() |> collect_first_elements()

  @spec values() :: list(binary())
  def values, do: options() |> collect_second_elements()

  @spec options() :: list({binary(), binary()})
  def options,
    do: [
      {gettext("Family"), "family"},
      {gettext("Friend"), "friend"},
      {gettext("Partner or roommate"), "partner_or_roommate"},
      {gettext("Co-worker"), "co-worker"},
      {gettext("Neighbor"), "neighbor"},
      {gettext("Healthcare worker"), "health_care_worker"},
      {gettext("Teacher/childcare"), "teacher_childcare"},
      {gettext("Service provider"), "service_provider"},
      {gettext("Other"), "other"}
    ]
end
