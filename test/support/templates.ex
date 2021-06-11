defmodule EpiContacts.TestTemplates do
  @moduledoc """
  Renders test fixture templates allowing for interpolation of test data
  """

  use Phoenix.Template, root: "test/fixtures/templates"

  def render(template, assigns) do
    render_template(template, assigns)
  end
end
