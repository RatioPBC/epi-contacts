defmodule EpiContacts.PostContactsBatch do
  @moduledoc """
  Batch worker that creates contacts in CommCare.
  """

  use Oban.Pro.Workers.Batch, queue: :default

  alias EpiContacts.{PatientCase, Contact}
  alias EpiContacts.Commcare.Client, as: CommcareClient

  @impl true
  def process(%_{args: %{"patient_case" => patient_case, "contact" => contact}}) do
    contact_id = PatientCase.generate_contact_id(patient_case)
    contact = %{contact | "contact_id" => contact_id} |> Contact.from_string_map()
    CommcareClient.post_contact(patient_case, contact)
  end
end
