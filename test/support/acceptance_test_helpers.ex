defmodule EpiContactsWeb.AcceptanceTestHelpers do
  @moduledoc """
  Acceptance test utilities
  """

  use Wallaby.DSL
  import Wallaby.Query, only: [css: 1]

  def save_and_open_screenshot(session) do
    new_session = take_screenshot(session)
    path = new_session.screenshots |> List.last()
    System.cmd("open", [path])
    new_session
  end

  def sos(session), do: save_and_open_screenshot(session)

  def save_and_open_page(session) do
    {:ok, path} = Briefly.create(extname: ".html")
    File.write!(path, Browser.page_source(session))
    System.cmd("open", [path])
    session
  end

  def sop(session), do: save_and_open_page(session)

  def click_submit(session), do: session |> click(css("button[type='submit']"))

  def click_button(session, type) when type in [:add_contact], do: session |> click(css("#add-contact-button"))
  def click_button(session, type) when type in [:submit_contact], do: session |> click(css("#submit-contact-button"))

  def click_button(session, type) when type in [:submit_to_commcare],
    do: session |> click(css("#submit-to-commcare-button"))

  def click_button(session, type) when type in [:back, :next, :skip, :yes, :no],
    do: session |> click(css("##{type}-button"))
end
