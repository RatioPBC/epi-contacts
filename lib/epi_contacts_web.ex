defmodule EpiContactsWeb do
  @moduledoc """
  The entrypoint for defining your web interface, such
  as controllers, views, channels and so on.

  This can be used in your application as:

      use EpiContactsWeb, :controller
      use EpiContactsWeb, :view

  The definitions below will be executed for every view,
  controller, etc, so keep them short and clean, focused
  on imports, uses and aliases.

  Do NOT define functions inside the quoted expressions
  below. Instead, define any helper function in modules
  and import those modules here.
  """

  def controller do
    quote do
      use Phoenix.Controller, namespace: EpiContactsWeb

      import Plug.Conn
      import EpiContacts.Gettext
      alias EpiContactsWeb.Router.Helpers, as: Routes
    end
  end

  def view do
    quote do
      use Phoenix.View,
        root: "lib/epi_contacts_web/templates",
        namespace: EpiContactsWeb

      # Import convenience functions from controllers
      import Phoenix.Controller, only: [get_flash: 1, get_flash: 2, view_module: 1]

      # Include shared imports and aliases for views
      unquote(view_helpers())
    end
  end

  def live_view do
    quote do
      use Phoenix.LiveView,
        layout: {EpiContactsWeb.LayoutView, "live.html"}

      unquote(view_helpers())
    end
  end

  def live_component do
    quote do
      use Phoenix.LiveComponent

      unquote(view_helpers())
    end
  end

  def router do
    quote do
      use Phoenix.Router

      import Plug.Conn
      import Phoenix.Controller
      import Phoenix.LiveView.Router
    end
  end

  def channel do
    quote do
      use Phoenix.Channel
      import EpiContacts.Gettext
    end
  end

  defp view_helpers do
    quote do
      # Use all HTML functionality (forms, tags, etc)
      use Phoenix.HTML

      # Import LiveView helpers (live_render, live_component, live_patch, etc)
      import Phoenix.LiveView.Helpers

      # Import basic rendering functionality (render, render_layout, etc)
      import Phoenix.View

      import EpiContactsWeb.ErrorHelpers
      import EpiContactsWeb.LayoutHelpers
      import EpiContacts.Gettext
      alias EpiContactsWeb.Router.Helpers, as: Routes

      def noreply(socket), do: {:noreply, socket}
      def ok(socket), do: {:ok, socket}

      # This was adapted from phoenix/live_dashboard/helpers/live_helpers.ex:8
      # Is this necessary?  Shouldn't these functions come for "free" when the routes are defined?
      # Why am I having to do this???
      def questionnaire_path(socket, action, params \\ []) do
        apply(
          socket.router.__helpers__(),
          :questionnaire_path,
          [socket, action, params]
        )
      end

      @spec days_of_the_week_options() :: list({binary(), binary()})
      def days_of_the_week_options,
        do: [
          {gettext("Monday"), "1"},
          {gettext("Tuesday"), "2"},
          {gettext("Wednesday"), "3"},
          {gettext("Thursday"), "4"},
          {gettext("Friday"), "5"},
          {gettext("Saturday"), "6"},
          {gettext("Sunday"), "7"}
        ]

      @spec days_of_the_week() :: list(binary())
      def days_of_the_week, do: days_of_the_week_options() |> collect_first_elements()

      @spec languages() :: list(binary())
      def languages, do: languages_options() |> collect_first_elements()

      @spec languages_options() :: list({binary(), binary()})
      def languages_options,
        do: [
          {gettext("English"), "en"},
          {gettext("Spanish"), "es"},
          {gettext("Chinese Cantonese"), "chinese_cantonese"},
          {gettext("Chinese Mandarin"), "chinese_mandarin"},
          {gettext("Russian"), "ru"},
          {gettext("Haitian Creole"), "haitian_creole"},
          {gettext("Hebrew"), "hebrew"},
          {gettext("Hindi"), "hindi"},
          {gettext("Bengali"), "bengali"},
          {gettext("Korean"), "korean"},
          {gettext("Arabic"), "arabic"},
          {gettext("France"), "fra"},
          {gettext("Italian"), "italian"},
          {gettext("Yiddish"), "yiddish"},
          {gettext("Polish"), "polish"},
          {gettext("Swahili"), "swahili"},
          {gettext("Other"), "other"}
        ]

      @spec locations_options() :: list({binary(), binary()})
      def locations_options,
        do: [
          {gettext("At home (household member or friend)"), "household"},
          {gettext("At home (caretaker)"), "caretaker"},
          {gettext("Place of worship"), "church"},
          {gettext("Healthcare facility"), "health_care"},
          {gettext("Nursing/Assisted living"), "nursing_assisted_living_home"},
          {gettext("School setting"), "school_setting"},
          {gettext("Workplace"), "workplace"},
          {gettext("Other"), "other"}
        ]

      @spec locations() :: list(binary())
      def locations,
        do: locations_options() |> collect_first_elements()

      @spec months_options() :: list({binary(), binary()})
      def months_options,
        do: [
          {gettext("January"), "1"},
          {gettext("February"), "2"},
          {gettext("March"), "3"},
          {gettext("April"), "4"},
          {gettext("May"), "5"},
          {gettext("June"), "6"},
          {gettext("July"), "7"},
          {gettext("August"), "8"},
          {gettext("September"), "9"},
          {gettext("October"), "10"},
          {gettext("November"), "11"},
          {gettext("December"), "12"}
        ]

      @spec months() :: list(binary())
      def months, do: months_options() |> collect_first_elements()

      def relationships_options,
        do: [
          {gettext("Family"), "family"},
          {gettext("Friend"), "friend"},
          {gettext("Partner or roommate"), "partner_or_roommate"},
          {gettext("Co-worker"), "co-worker"},
          {gettext("Neighbor"), "neighbor"},
          {gettext("Healthcare worker"), "health_care_worker"},
          {gettext("Teacher/childcare"), "teacher_childcare"},
          {gettext("Service provider"), "service_provider"},
          {gettext("Other"), "other"}
        ]

      defp collect_first_elements(list) do
        Enum.map(list, &elem(&1, 0))
      end
    end
  end

  @doc """
  When used, dispatch to the appropriate controller/view/etc.
  """
  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
