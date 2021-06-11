defmodule EpiContacts.AccountsTest do
  use EpiContacts.DataCase

  alias EpiContacts.Accounts
  import EpiContacts.AccountsFixtures
  alias EpiContacts.Accounts.{Admin, AdminToken}

  describe "get_admin_by_email/1" do
    test "does not return the admin if the email does not exist" do
      refute Accounts.get_admin_by_email("unknown@example.com")
    end

    test "returns the admin if the email exists" do
      %{id: id} = admin = admin_fixture()
      assert %Admin{id: ^id} = Accounts.get_admin_by_email(admin.email)
    end
  end

  describe "get_admin_by_email_password_and_totp/2" do
    test "does not return the admin if the email does not exist" do
      refute Accounts.get_admin_by_email_password_and_totp("unknown@example.com", "hello world!", verification_code())
    end

    test "does not return the admin if the password is not valid" do
      admin = admin_fixture()
      refute Accounts.get_admin_by_email_password_and_totp(admin.email, "invalid", verification_code())
    end

    test "does not return the admin if the verification code is not valid" do
      admin = admin_fixture()
      refute Accounts.get_admin_by_email_password_and_totp(admin.email, valid_admin_password(), "123456")
    end

    test "returns the admin if the email and password are valid" do
      %{id: id} = admin = admin_fixture()

      assert %Admin{id: ^id} =
               Accounts.get_admin_by_email_password_and_totp(admin.email, valid_admin_password(), verification_code())
    end
  end

  describe "get_admin!/1" do
    test "raises if id is invalid" do
      assert_raise Ecto.NoResultsError, fn ->
        Accounts.get_admin!(-1)
      end
    end

    test "returns the admin with the given id" do
      %{id: id} = admin = admin_fixture()
      assert %Admin{id: ^id} = Accounts.get_admin!(admin.id)
    end
  end

  #       assert "should be at most 80 character(s)" in errors_on(changeset).password

  describe "register_admin/1" do
    test "requires email and password to be set" do
      {:error, changeset} = Accounts.register_admin(%{})

      assert %{email: ["can't be blank"]} = errors_on(changeset)
    end

    test "validates email and password when given" do
      {:error, changeset} = Accounts.register_admin(%{email: "not valid", password: "not valid"})

      assert %{email: ["must have the @ sign and no spaces"]} = errors_on(changeset)
    end

    test "validates maximum values for email and password for security" do
      too_long = String.duplicate("db", 100)
      {:error, changeset} = Accounts.register_admin(%{email: too_long, password: too_long})
      assert "should be at most 160 character(s)" in errors_on(changeset).email
    end

    test "validates email uniqueness" do
      %{email: email} = admin_fixture()
      {:error, changeset} = Accounts.register_admin(%{email: email})
      assert "has already been taken" in errors_on(changeset).email

      # Now try with the upper cased email too, to check that email case is ignored.
      {:error, changeset} = Accounts.register_admin(%{email: String.upcase(email)})
      assert "has already been taken" in errors_on(changeset).email
    end

    test "registers admins with a hashed password" do
      email = unique_admin_email()
      {:ok, admin} = Accounts.register_admin(valid_admin_attributes(email: email))
      assert admin.email == email
      assert is_binary(admin.hashed_password)
      assert is_nil(admin.password)
      assert is_binary(admin.totp_secret)
    end
  end

  describe "generate_admin_session_token/1" do
    setup do
      %{admin: admin_fixture()}
    end

    test "generates a token", %{admin: admin} do
      token = Accounts.generate_admin_session_token(admin)
      assert admin_token = Repo.get_by(AdminToken, token: token)
      assert admin_token.context == "session"

      # Creating the same token for another admin should fail
      assert_raise Ecto.ConstraintError, fn ->
        Repo.insert!(%AdminToken{
          token: admin_token.token,
          admin_id: admin_fixture().id,
          context: "session"
        })
      end
    end
  end

  describe "get_admin_by_session_token/1" do
    setup do
      admin = admin_fixture()
      token = Accounts.generate_admin_session_token(admin)
      %{admin: admin, token: token}
    end

    test "returns admin by token", %{admin: admin, token: token} do
      assert session_admin = Accounts.get_admin_by_session_token(token)
      assert session_admin.id == admin.id
    end

    test "does not return admin for invalid token" do
      refute Accounts.get_admin_by_session_token("oops")
    end

    test "does not return admin for expired token", %{token: token} do
      {1, nil} = Repo.update_all(AdminToken, set: [inserted_at: ~N[2020-01-01 00:00:00]])
      refute Accounts.get_admin_by_session_token(token)
    end
  end

  describe "delete_session_token/1" do
    test "deletes the token" do
      admin = admin_fixture()
      token = Accounts.generate_admin_session_token(admin)
      assert Accounts.delete_session_token(token) == :ok
      refute Accounts.get_admin_by_session_token(token)
    end
  end

  describe "inspect/2" do
    test "does not include password" do
      refute inspect(%Admin{password: "123456"}) =~ "password: \"123456\""
    end
  end

  describe "otp_uri/2" do
    test "when no issuer is provided" do
      admin = admin_fixture()

      assert Accounts.otp_uri(admin) ==
               "otpauth://totp/SMC:#{admin.email}?secret=H4MCUHS7ORIHS2TG&issuer=SMC"
    end

    test "when an issuer is provided" do
      admin = admin_fixture()

      assert Accounts.otp_uri(admin, "share_someones_contacts") ==
               "otpauth://totp/share_someones_contacts:#{admin.email}?secret=H4MCUHS7ORIHS2TG&issuer=share_someones_contacts"
    end
  end
end
