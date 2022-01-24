defmodule EpiContacts.Test.Xml do
  @moduledoc """
    test support helpers for parsing XML
  """

  def attr(document, css_selector, attribute_name),
    do: document |> Floki.attribute(css_selector, attribute_name) |> Euclid.List.only!()

  def text(document, css_selector),
    do: document |> Floki.find(css_selector |> String.downcase()) |> Floki.text()
end
