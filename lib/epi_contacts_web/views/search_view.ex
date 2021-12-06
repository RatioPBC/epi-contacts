defmodule EpiContactsWeb.SearchView do
  use EpiContactsWeb, :view

  def number_of_search_results(nil), do: "0 results"
  def number_of_search_results([_one_result]), do: "1 result"
  def number_of_search_results(search_results), do: "#{length(search_results)} results"

  def full_name(%{first_name: first_name, middle_name: middle_name, last_name: last_name}) do
    [first_name, middle_name, last_name]
    |> Enum.reject(&(!&1))
    |> Enum.join(" ")
  end

  def show_if_present(nil), do: nil

  def show_if_present(something) do
    content_tag(:h4, something)
  end

  def raw_phone_number(nil), do: nil

  def raw_phone_number(phone_number) do
    phone_number
    |> String.replace("(", "")
    |> String.replace(")", "")
    |> String.replace("-", "")
    |> String.replace(" ", "")
  end
end
