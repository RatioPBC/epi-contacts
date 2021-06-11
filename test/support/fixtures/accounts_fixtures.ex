defmodule EpiContacts.AccountsFixtures do
  @moduledoc """
  This module defines test helpers for creating
  entities via the `EpiContacts.Accounts` context.
  """

  def unique_admin_email, do: "admin#{System.unique_integer()}@example.com"
  def valid_admin_password, do: "hello 16 char world!"
  def totp_secret, do: <<63, 24, 42, 30, 95, 116, 80, 121, 106, 102>>
  def verification_code(secret \\ totp_secret()), do: NimbleTOTP.verification_code(secret)

  @spec valid_admin_attributes(map) :: map
  def valid_admin_attributes(attrs \\ %{}) do
    Enum.into(attrs, %{
      email: unique_admin_email(),
      password: valid_admin_password(),
      password_confirmation: valid_admin_password(),
      totp_secret: totp_secret()
    })
  end

  @spec admin_fixture(map) :: EpiContacts.Accounts.Admin.t()
  def admin_fixture(attrs \\ %{}) do
    {:ok, admin} =
      attrs
      |> valid_admin_attributes()
      |> EpiContacts.Accounts.register_admin()

    admin
  end
end
