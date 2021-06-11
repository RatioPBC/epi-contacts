defmodule EpiContactsWeb.ReviewComponentText do
  use EpiContactsWeb.ConnCase, async: false

  import Mox
  import Phoenix.LiveViewTest

  alias EpiContactsWeb.ReviewComponent

  setup :verify_on_exit!

  defmodule TestLiveView do
    alias EpiContactsWeb.ReviewComponent

    @patient_case "test/fixtures/commcare/case-with-test-results-and-contacts.json"
                  |> File.read!()
                  |> Jason.decode!()

    @skip_path nil

    use EpiContactsWeb.Test.ComponentEmbeddingLiveView,
      default_assigns: [patient_case: @patient_case, contacts: [], skip_path: @skip_path]

    def render(assigns) do
      ~L"""
      <%= live_component @socket, ReviewComponent,
        id: "test-component",
        patient_case: @patient_case,
        skip_path: @skip_path,
        contacts: @contacts %>
      """
    end
  end

  test "shows an error if agree to share is not checked", %{conn: conn} do
    {:ok, view, _html} = live_isolated(conn, TestLiveView)

    assert view
           |> element("#review")
           |> render_submit(%{
             "review" => %{}
           }) =~ "must be accepted"
  end
end
