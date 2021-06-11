defmodule EpiContacts do
  @moduledoc """
  EpiContacts keeps the contexts that define your domain
  and business logic.

  Contexts are also responsible for managing your data, regardless
  if it comes from the database, an external API or others.
  """

  def signer do
    Application.get_env(:epi_contacts, __MODULE__)[:signer]
  end
end
