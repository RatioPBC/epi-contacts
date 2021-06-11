defmodule EpiContacts.SecureId do
  @moduledoc """
  This module provides an interface to generate expirable paseto tokens with json payloads
  """

  @format "{YY}-{M}-{D}/{h24}"
  @encoded_at_field "e"
  @valid_duration Timex.Duration.from_hours(48)

  @spec encode(data :: map()) :: any()
  def encode(data) do
    payload = data |> Map.put(@encoded_at_field, DateTime.utc_now() |> Timex.format!(@format)) |> Jason.encode!()
    Paseto.generate_token("v2", "local", payload, secure_id_key())
  end

  @spec decode!(secure_id :: binary()) :: term()
  def decode!(secure_id) do
    {:ok, data} = decode(secure_id)
    data
  end

  @spec decode(secure_id :: binary()) :: {:error, :expired | term()} | {:ok, map()}
  def decode(secure_id) do
    with {:ok, %Paseto.Token{payload: payload}} <- Paseto.parse_token(secure_id, secure_id_key()),
         {:ok, %{@encoded_at_field => encoded_at} = data} <- Jason.decode(payload),
         {:ok, encoded_at} <- Timex.parse(encoded_at, @format) do
      encoded_at
      |> Timex.add(@valid_duration)
      |> Timex.compare(DateTime.utc_now())
      |> case do
        -1 -> {:error, :expired}
        _ -> {:ok, data}
      end
    end
  end

  @spec secure_id_key() :: <<_::32>>
  def secure_id_key,
    do:
      :epi_contacts
      |> Application.fetch_env!(:secure_id_key)
      |> Base.decode64!()
end
