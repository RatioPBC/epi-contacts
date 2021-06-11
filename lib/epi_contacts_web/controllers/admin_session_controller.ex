defmodule EpiContactsWeb.AdminSessionController do
  use EpiContactsWeb, :controller

  alias EpiContacts.Accounts
  alias EpiContactsWeb.AdminAuth

  def new(conn, _params) do
    render(conn, "new.html", error_message: nil)
  end

  def create(conn, %{"admin" => admin_params}) do
    %{"email" => email, "password" => password, "verification_code" => verification_code} = admin_params

    if admin = Accounts.get_admin_by_email_password_and_totp(email, password, verification_code) do
      AdminAuth.log_in_admin(conn, admin, admin_params)
    else
      render(conn, "new.html", error_message: "Invalid email or password")
    end
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "Logged out successfully.")
    |> AdminAuth.log_out_admin()
  end
end
