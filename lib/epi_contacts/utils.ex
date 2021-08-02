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
end
