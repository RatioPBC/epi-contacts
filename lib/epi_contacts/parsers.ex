defmodule EpiContacts.Parsers do
  @moduledoc """
  parsers
  """

  def valid_uuid?(uuid), do: match?({:ok, _}, Ecto.UUID.dump(uuid))

  def datetime_with_or_without_zone(nil), do: nil

  def datetime_with_or_without_zone(datetime_string) do
    DateTime.from_iso8601(datetime_string)
    |> case do
      {:ok, datetime, _offset} -> {:ok, datetime}
      {:error, _} -> interpret_as_naive_datetime(datetime_string)
    end
    |> case do
      {:ok, datetime} -> datetime
      _not_ok -> nil
    end
  end

  defp interpret_as_naive_datetime(datetime_string) do
    case NaiveDateTime.from_iso8601(datetime_string) do
      {:ok, naive_datetime} ->
        naive_datetime |> DateTime.from_naive("Etc/UTC")

      not_ok ->
        not_ok
    end
  end
end
