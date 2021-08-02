defmodule EpiContacts.Utils do
  @moduledoc """
  A grab-bag of fun functions.
  """

  @spec collect_first_elements(list()) :: list()
  def collect_first_elements(list) do
    Enum.map(list, &elem(&1, 0))
  end

  @spec collect_second_elements(list()) :: list()
  def collect_second_elements(list) do
    Enum.map(list, &elem(&1, 1))
  end

  @spec traverse_errors(Ecto.Changeset.t()) :: %{required(atom) => [String.t() | map]}
  def traverse_errors(changeset) do
    Ecto.Changeset.traverse_errors(changeset, fn {msg, opts} ->
      Enum.reduce(opts, msg, fn {key, value}, acc ->
        String.replace(acc, "%{#{key}}", to_string(value))
      end)
    end)
  end
end
