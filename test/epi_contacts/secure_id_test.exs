defmodule EpiContacts.SecureIdTest do
  use ExUnit.Case
  import EpiContacts.Testing.SecureId, only: [backdate_paseto: 1, backdate_paseto: 2]
  alias EpiContacts.SecureId
  @encoded_at_field "e"

  test "round trip" do
    assert %{"id" => "some id", "other" => "other", @encoded_at_field => _} =
             %{id: "some id", other: "other"}
             |> SecureId.encode()
             |> SecureId.decode!()

    assert {:ok, %{"id" => "some id", "other" => "other", @encoded_at_field => _}} =
             %{id: "some id", other: "other"}
             |> SecureId.encode()
             |> SecureId.decode()
  end

  test "secure ids expire after 14 days" do
    alias Timex.Duration

    fourty_seven_hour_old_paseto = Duration.from_hours(47) |> backdate_paseto(data: %{id: "id"})
    assert {:ok, %{"id" => "id", @encoded_at_field => _}} = SecureId.decode(fourty_seven_hour_old_paseto)

    assert 49 |> Duration.from_hours() |> backdate_paseto(encoded_at_field: @encoded_at_field) |> SecureId.decode() ==
             {:error, :expired}

    expired_paseto = 49 |> Duration.from_hours() |> backdate_paseto()
    assert_raise MatchError, fn -> SecureId.decode!(expired_paseto) end
  end
end
