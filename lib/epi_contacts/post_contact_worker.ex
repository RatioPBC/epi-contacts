defmodule EpiContacts.PostContactWorker do
  @moduledoc """
  Oban worker that posts contacts gathered by the questionnaire back to commcare.
  """

  use Oban.Worker, queue: :default
  require Logger

  alias EpiContacts.{PatientCase, Contact}
  alias EpiContacts.Commcare.Client, as: CommcareClient

  @impl Oban.Worker
  def perform(%_{args: %{"patient_case" => patient_case, "contact" => contact}}),
    do: CommcareClient.post_contact(patient_case, Contact.from_string_map(contact))

  def enqueue_contacts(%{contacts: contacts, patient_case: patient_case}) do
    for contact <- contacts do
      contact = %Contact{contact | contact_id: PatientCase.generate_contact_id(patient_case)}

      %{patient_case: patient_case, contact: contact}
      |> __MODULE__.new()
      |> Oban.insert()
    end

    :ok
  end
end
