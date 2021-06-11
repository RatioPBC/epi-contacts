defmodule EpiContacts.IdentityConfirmationSession do
  @moduledoc """
  stores identity confirmation attempts and lockout state
  """

  use Ecto.Schema
  import Ecto.Changeset

  @primary_key {:id, :binary_id, autogenerate: true}
  @foreign_key_type :binary_id
  schema("identity_confirmation_sessions") do
    field(:external_id, :string)
    field(:locked_at, :naive_datetime)
    field(:unlocked_at, :naive_datetime)

    embeds_many :attempts, Attempt do
      field(:successful, :boolean)
      field(:dob, :date)
      timestamps()
    end

    timestamps()
  end

  def changeset(identity_confirmation_session, attrs) do
    cast(identity_confirmation_session, attrs, [:external_id, :locked_at, :unlocked_at])
  end

  def upsert_conflict_target do
    "(external_id, coalesce(unlocked_at, '19000101')) WHERE coalesce(unlocked_at, '19000101') = '19000101'"
  end
end
