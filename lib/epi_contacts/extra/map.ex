defmodule EpiContacts.Extra.Map do
  @moduledoc """
  Provides helpers for mutating Map's
  """

  def atomize_keys(map) when is_map(map) do
    map
    |> Enum.reduce(%{}, fn {key, value}, map_acc ->
      value = atomize_keys(value)
      map_acc |> Map.put(atomize(key), value)
    end)
  end

  def atomize_keys(value), do: value

  # sobelow_skip ["DOS.StringToAtom"]
  defp atomize(key) when is_binary(key), do: String.to_atom(key)
  defp atomize(key), do: key
end
