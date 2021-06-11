defmodule EpiContacts.Testing.SecureId do
  @moduledoc false

  alias EpiContacts.SecureId

  def backdate_paseto(duration, opts \\ []) do
    data = Keyword.get(opts, :data, %{})
    encoded_at_field = Keyword.get(opts, :encoded_at_field, "e")

    Paseto.generate_token(
      "v2",
      "local",
      data
      |> Map.put(
        encoded_at_field,
        DateTime.utc_now()
        |> Timex.subtract(duration)
        |> Timex.format!("{YY}-{M}-{D}/{h24}")
      )
      |> Jason.encode!(),
      SecureId.secure_id_key()
    )
  end
end
