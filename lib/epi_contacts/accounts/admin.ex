defmodule EpiContacts.Accounts.Admin do
  @moduledoc """
  # A database-backed record that represents administrators of the system.

  Creation and managment of these records is outside of the scope of
  this application. Each admin must have a configured password and
  totp secret, and is identified by their email address
  """

  use Ecto.Schema
  import Ecto.Changeset

  @derive {Inspect, except: [:password]}
  schema "admins" do
    field(:email, :string)
    field(:password, :string, virtual: true)
    field(:hashed_password, :string, null: false)
    field(:totp_secret, :binary, null: false, redact: true)

    timestamps()
  end

  @doc """
  A admin changeset for registration.

  It is important to validate the length of both email and password.
  Otherwise databases may truncate the email without warnings, which
  could lead to unpredictable or insecure behaviour. Long passwords may
  also be very expensive to hash for certain algorithms.

  ## Options

    * `:hash_password` - Hashes the password so it can be stored securely
      in the database and ensures the password field is cleared to prevent
      leaks in the logs. If password hashing is not needed and clearing the
      password field is not desired (like when using this changeset for
      validations on a LiveView form), this option can be set to `false`.
      Defaults to `true`.
  """
  def registration_changeset(admin, attrs, opts \\ []) do
    admin
    |> cast(attrs, [:email, :totp_secret, :password])
    |> validate_password(opts)
    |> validate_confirmation(:password, message: "does not match password")
    |> validate_required([:totp_secret])
    |> validate_email()
  end

  defp validate_email(changeset) do
    changeset
    |> validate_required([:email])
    |> validate_format(:email, ~r/^[^\s]+@[^\s]+$/, message: "must have the @ sign and no spaces")
    |> validate_length(:email, max: 160)
    |> unsafe_validate_unique(:email, EpiContacts.Repo)
    |> unique_constraint(:email)
  end

  defp validate_password(changeset, opts) do
    changeset
    |> validate_required([:password])
    |> validate_length(:password, min: 16, max: 80)
    |> maybe_hash_password(opts)
  end

  defp maybe_hash_password(changeset, opts) do
    hash_password? = Keyword.get(opts, :hash_password, true)
    password = get_change(changeset, :password)

    if hash_password? && password && changeset.valid? do
      changeset
      |> put_change(:hashed_password, Bcrypt.hash_pwd_salt(password))
      |> delete_change(:password)
    else
      changeset
    end
  end

  @doc """
  Confirms the account by setting `confirmed_at`.
  """
  def confirm_changeset(admin) do
    now = NaiveDateTime.utc_now() |> NaiveDateTime.truncate(:second)
    change(admin, confirmed_at: now)
  end

  @doc """
  Verifies the password.

  If there is no admin or the admin doesn't have a password, we call
  `Bcrypt.no_user_verify/0` to avoid timing attacks.
  """
  @spec valid_password?(Admin.t() | nil, binary | nil) :: boolean
  def valid_password?(%EpiContacts.Accounts.Admin{hashed_password: hashed_password}, password)
      when is_binary(hashed_password) and byte_size(password) > 0 do
    Bcrypt.verify_pass(password, hashed_password)
  end

  def valid_password?(_, _) do
    Bcrypt.no_user_verify()
    false
  end

  @doc """
  Verifies the otp code against the admin's totp secret.
  """
  def valid_verification_code?(%EpiContacts.Accounts.Admin{totp_secret: secret}, verification_code),
    do: NimbleTOTP.valid?(secret, verification_code)

  def valid_verification_code?(_, _), do: false

  @doc """
  Validates the current password otherwise adds an error to the changeset.
  """
  def validate_current_password(changeset, password) do
    if valid_password?(changeset.data, password) do
      changeset
    else
      add_error(changeset, :current_password, "is not valid")
    end
  end
end
