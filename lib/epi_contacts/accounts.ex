defmodule EpiContacts.Accounts do
  @moduledoc """
  The Accounts context.
  """

  import Ecto.Query, warn: false
  alias EpiContacts.Repo
  alias EpiContacts.Accounts.{Admin, AdminToken}

  ## Database getters

  @doc """
  Gets a admin by email.

  ## Examples

      iex> get_admin_by_email("foo@example.com")
      %Admin{}

      iex> get_admin_by_email("unknown@example.com")
      nil

  """
  def get_admin_by_email(email) when is_binary(email) do
    Repo.get_by(Admin, email: email)
  end

  @doc """
  Gets a admin by email and password.

  ## Examples

      iex> get_admin_by_email_and_password("foo@example.com", "correct_password")
      %Admin{}

      iex> get_admin_by_email_and_password("foo@example.com", "invalid_password")
      nil

  """
  def get_admin_by_email_password_and_totp(email, password, verification_code)
      when is_binary(email) and is_binary(password) and is_binary(verification_code) do
    admin = Repo.get_by(Admin, email: email)
    valid_password? = Admin.valid_password?(admin, password)
    valid_totp? = Admin.valid_verification_code?(admin, verification_code)
    if valid_password? && valid_totp?, do: admin
  end

  @doc """
  Gets a single admin.

  Raises `Ecto.NoResultsError` if the Admin does not exist.

  ## Examples

      iex> get_admin!(123)
      %Admin{}

      iex> get_admin!(456)
      ** (Ecto.NoResultsError)

  """
  def get_admin!(id), do: Repo.get!(Admin, id)

  ## Admin registration

  @doc """
  Registers a admin.

  ## Examples

      iex> register_admin(%{field: value})
      {:ok, %Admin{}}

      iex> register_admin(%{field: bad_value})
      {:error, %Ecto.Changeset{}}

  """
  def register_admin(attrs) do
    %Admin{}
    |> Admin.registration_changeset(attrs)
    |> Repo.insert()
  end

  ## Session

  @doc """
  Generates a session token.
  """
  def generate_admin_session_token(admin) do
    {token, admin_token} = AdminToken.build_session_token(admin)
    Repo.insert!(admin_token)
    token
  end

  @doc """
  Gets the admin with the given signed token.
  """
  def get_admin_by_session_token(token) do
    {:ok, query} = AdminToken.verify_session_token_query(token)
    Repo.one(query)
  end

  @doc """
  Deletes the signed token with the given context.
  """
  def delete_session_token(token) do
    Repo.delete_all(AdminToken.token_and_context_query(token, "session"))
    :ok
  end

  @doc """
  Builds an OTP URI for a given admin that can be added to an authenticator application.
  """

  def otp_uri(admin, issuer \\ "SMC") do
    NimbleTOTP.otpauth_uri("#{issuer}:#{admin.email}", admin.totp_secret, issuer: issuer)
  end
end
