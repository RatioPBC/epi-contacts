defmodule EpiContactsWeb.QuestionnaireView do
  use EpiContactsWeb, :view
  import EpiContacts.Gettext
  import EpiContacts.Contact, only: [initials: 1]

  import EpiContacts.PatientCase,
    only: [start_of_infectious_period: 1, end_of_infectious_period: 1, full_name: 1]

  import EpiContactsWeb.PageView, only: [contact_blurb: 0]

  alias EpiContacts.{Contact, PatientCase}

  def format(%Date{} = date, opts \\ []) do
    locale = opts[:locale] || get_locale() || default_locale()

    Gettext.with_locale(locale, fn ->
      weekday = Timex.lformat!(date, "{WDfull}", locale)
      month = Timex.lformat!(date, "{Mfull}", locale)

      day = Timex.format!(date, "{D}")

      Gettext.gettext(EpiContacts.Gettext, "Friday, Sep 13 - %{weekday}, %{month} %{day}",
        weekday: weekday,
        month: month,
        day: day
      )
    end)
  end

  def display_end_of_historical_infectious_period(%Date{} = end_date, %Date{} = today \\ Timex.today()) do
    case Date.compare(end_date, today) do
      :lt -> format(end_date)
      :gt -> gettext("today")
      _ -> gettext("today")
    end
  end

  def display_end_of_isolation_period(%Date{} = end_date) do
    end_date |> Timex.shift(days: 3) |> Timex.format!("%B %d", :strftime)
  end

  def existing_contacts_section(patient_case) do
    patient_case
    |> PatientCase.existing_contacts()
    |> do_existing_contacts_section()
  end

  def do_existing_contacts_section([]) do
    assigns = %{use_copy: gettext("Use this questionnaire to add people you haven’t told us about.")}

    ~H"""
    <p>
      <%= @use_copy %>
    </p>
    """
  end

  def do_existing_contacts_section(existing_contacts) do
    assigns = %{
      existing_contacts: existing_contacts,
      use_copy: gettext("Use this questionnaire to add people you haven’t told us about."),
      spoken_copy: gettext("If you have already spoken with us..."),
      contact_initials_header: gettext("Contact's initials"),
      last_4_header: gettext("Last 4 digits of phone")
    }

    ~H"""
    <p>
      <%= @use_copy %>
      <br />
      <%= @spoken_copy %>
    </p>

    <table>
      <thead>
        <tr>
          <th><%= @contact_initials_header %></th>
          <th><%= @last_4_header %></th>
        </tr>
      </thead>
      <tbody>
      <%= for contact <- @existing_contacts do %>
        <tr>
          <td><%= initials(contact) %></td>
          <td><%= phone_number_mask(contact) %></td>
        </tr>
      <% end %>
      </tbody>
    </table>
    """
  end

  @spec infectious_period(map()) :: Phoenix.HTML.safe()
  def infectious_period(patient_case, opts \\ []) do
    locale = opts[:locale] || get_locale() || default_locale()

    assigns = %{
      start_date: patient_case |> start_of_infectious_period() |> format(locale: locale),
      end_date: patient_case |> end_of_infectious_period() |> display_end_of_historical_infectious_period(),
      from: gettext("from"),
      to: gettext("to")
    }

    ~H"""
    <%= @from %>
    <span class="date" data-tid="start-date"><%= @start_date %></span>
    <%= @to %>
    <span class="date" data-tid="end-date"><%= @end_date %></span>:
    """
  end

  @spec prep_header(map()) :: Phoenix.HTML.safe()
  def prep_header(patient_case) do
    prelude = gettext("Now, you'll be asked to add contacts you've seen")
    infectious_period_header(patient_case, prelude)
  end

  @spec house_header(map()) :: Phoenix.HTML.safe()
  def house_header(patient_case) do
    prelude = gettext("Who has been in your house with you")
    infectious_period_header(patient_case, prelude)
  end

  @spec social_header(map()) :: Phoenix.HTML.safe()
  def social_header(patient_case) do
    prelude = gettext("Who else have you seen")
    infectious_period_header(patient_case, prelude)
  end

  defp infectious_period_header(patient_case, prelude) do
    assigns = %{
      prelude: prelude,
      infectious_period: infectious_period(patient_case)
    }

    ~H"""
      <%= @prelude %> <%= @infectious_period %>
    """
  end

  def phone_number_mask(%Contact{phone: nil}), do: "Unavailable"
  def phone_number_mask(%Contact{phone: ""}), do: "Unavailable"

  def phone_number_mask(%Contact{phone: phone}) do
    <<last_4_reversed::binary-size(4), _::binary>> = String.reverse(phone)
    last_4 = String.reverse(last_4_reversed)
    "*** *** #{last_4}"
  end

  def exposed_on_select_options(patient_case, opts \\ []) do
    now = opts[:now] || Date.utc_today()
    locale = opts[:locale] || get_locale() || default_locale()

    start_of_infectious_period = PatientCase.start_of_infectious_period(patient_case)

    end_of_infectious_period = PatientCase.end_of_infectious_period(patient_case)

    end_of_range =
      case Date.compare(end_of_infectious_period, now) do
        :gt -> now
        _ -> end_of_infectious_period
      end

    start_of_infectious_period
    |> Date.range(end_of_range)
    |> Enum.map(fn date ->
      weekday = Timex.lformat!(date, "{WDfull}", locale)
      short_month = Timex.lformat!(date, "{Mshort}", locale)
      day = Timex.format!(date, "{D}")

      text =
        Gettext.with_locale(locale, fn ->
          gettext("Friday, Sep 13 - %{weekday}, %{month} %{day}", weekday: weekday, month: short_month, day: day)
        end)

      {text, Date.to_iso8601(date)}
    end)
  end
end
