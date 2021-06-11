defmodule EpiContacts.Review do
  @moduledoc """
  confirms the user agrees to terms
  """

  use Ecto.Schema
  import Ecto.Changeset

  embedded_schema do
    field(:agree_to_share, :boolean)
  end

  def validate(review, attrs) do
    review
    |> cast(attrs, [:agree_to_share])
    |> validate_acceptance(:agree_to_share)
  end
end
