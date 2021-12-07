defmodule EpiContactsWeb.QuestionnaireViewTest do
  use EpiContactsWeb.ConnCase, async: true

  alias EpiContactsWeb.QuestionnaireView, as: View
  alias Phoenix.HTML.Safe

  describe "format" do
    test "it formats the date for the user in English" do
      assert View.format(~D[2020-04-15], locale: "en") == "Wednesday, April 15"
    end

    test "it formats the date for the user in Spanish" do
      assert View.format(~D[2020-04-15], locale: "es") == "Miércoles 15 de Abril"
    end
  end

  describe "display_end_of_historical_infectious_period" do
    test "if the end of the infectious period is in past, show the formatted end date" do
      today = ~D[2020-04-01]
      end_date = ~D[2020-03-20]
      assert View.display_end_of_historical_infectious_period(end_date, today) == "Friday, March 20"
    end

    test "if the end of the infectious period is in the future, show the string 'today'" do
      today = ~D[2020-04-01]
      end_date = ~D[2020-04-10]
      assert View.display_end_of_historical_infectious_period(end_date, today) == "today"
    end

    test "if the end of the infectious period is today, show the string 'today'" do
      today = ~D[2020-04-01]
      end_date = ~D[2020-04-01]
      assert View.display_end_of_historical_infectious_period(end_date, today) == "today"
    end
  end

  describe "display_end_of_isolation_period" do
    test "it displays a date 3 days after the end of the infectious period" do
      end_date = ~D[2020-03-20]
      assert View.display_end_of_isolation_period(end_date) == "March 23"
    end
  end

  describe "phone_number_mask/1" do
    alias EpiContacts.Contact

    test "display only the last 4 digits" do
      contact = %Contact{phone: "5554443333"}
      assert View.phone_number_mask(contact) == "*** *** 3333"

      contact = %Contact{phone: ""}
      assert View.phone_number_mask(contact) == "Unavailable"

      contact = %Contact{phone: nil}
      assert View.phone_number_mask(contact) == "Unavailable"
    end
  end

  describe "existing_contacts_section/1" do
    test "displays contacts when they already exist" do
      patient_case = %{
        "child_cases" => %{
          "1" => %{
            "properties" => %{
              "case_type" => "contact",
              "first_name" => "John",
              "last_name" => "Doe",
              "phone_home" => "8887776666"
            }
          },
          "2" => %{"properties" => %{"case_type" => "lab_result"}}
        }
      }

      html =
        patient_case
        |> View.existing_contacts_section()
        |> html_for()

      assert_content(html)
      assert Floki.text(html) =~ gettext("If you have already spoken with us...")

      rows_text = text(html, "tbody tr")

      assert rows_text =~ "J.D."
      assert rows_text =~ "*** *** 6666"
    end

    test "only displays copy" do
      html =
        %{"child_cases" => %{}}
        |> View.existing_contacts_section()
        |> html_for()

      assert_content(html)
    end

    defp assert_content(html) do
      assert Floki.text(html) =~ gettext("Use this questionnaire to add people you haven’t told us about.")
    end
  end

  describe "infectious_period/1" do
    test "renders start & end date in English" do
      patient_case = %{
        "properties" => %{
          "isolation_start_date" => "2021-06-17"
        }
      }

      html =
        patient_case
        |> View.infectious_period()
        |> html_for()

      assert_infectious_period(html, "Tuesday, June 15", "Friday, June 25")
    end

    test "renders start & end date in Spanish" do
      patient_case = %{
        "properties" => %{
          "isolation_start_date" => "2021-06-17"
        }
      }

      html =
        patient_case
        |> View.infectious_period()
        |> html_for()

      assert_infectious_period(html, "Tuesday, June 15", "Friday, June 25")
    end
  end

  defp assert_infectious_period(html, start_span_text, end_span_text) do
    start_span = text(html, "[data-tid=start-date]")
    end_span = text(html, "[data-tid=end-date]")

    assert start_span == start_span_text
    assert end_span == end_span_text
  end

  defp escaped_text(text) do
    text
    |> Phoenix.HTML.html_escape()
    |> Phoenix.HTML.safe_to_string()
  end

  defp html_for(safe_string) do
    safe_string
    |> Safe.to_iodata()
    |> IO.iodata_to_binary()
    |> Floki.parse_fragment!()
  end

  defp text(html, query) do
    html
    |> Floki.find(query)
    |> Floki.text()
  end

  describe "headers" do
    @patient_case %{
      "properties" => %{
        "isolation_start_date" => "2021-06-17"
      }
    }

    test "prep_header/1" do
      prelude = gettext("Now, you'll be asked to add contacts you've seen")

      @patient_case
      |> View.prep_header()
      |> assert_infectious_header(prelude)
    end

    test "house_header/1" do
      prelude = gettext("Who has been in your house with you")

      @patient_case
      |> View.house_header()
      |> assert_infectious_header(prelude)
    end

    test "social_header/1" do
      prelude = gettext("Who else have you seen")

      @patient_case
      |> View.social_header()
      |> assert_infectious_header(prelude)
    end

    defp assert_infectious_header(safe_string, prelude) do
      html = html_for(safe_string)

      raw_html = Floki.raw_html(html)

      assert raw_html =~ escaped_text(prelude)
      assert_infectious_period(html, "Tuesday, June 15", "Friday, June 25")
    end
  end

  describe "exposed_on_select_options/1" do
    test "doesn't return future dates" do
      patient_case = %{"properties" => %{"isolation_start_date" => "2021-01-04"}}

      options = View.exposed_on_select_options(patient_case, now: ~D[2021-01-06])
      assert Enum.count(options) == 5

      patient_case = %{"properties" => %{"isolation_start_date" => "2020-12-20"}}

      options = View.exposed_on_select_options(patient_case)
      assert Enum.count(options) == 11
    end

    test "handles English" do
      patient_case = %{"properties" => %{"isolation_start_date" => "2020-12-20"}}

      options = View.exposed_on_select_options(patient_case)

      assert match?(
               [
                 {"Friday, Dec 18", "2020-12-18"},
                 {"Saturday, Dec 19", "2020-12-19"},
                 {"Sunday, Dec 20", "2020-12-20"},
                 {"Monday, Dec 21", "2020-12-21"},
                 {"Tuesday, Dec 22", "2020-12-22"},
                 {"Wednesday, Dec 23", "2020-12-23"},
                 {"Thursday, Dec 24", "2020-12-24"},
                 {"Friday, Dec 25", "2020-12-25"},
                 {"Saturday, Dec 26", "2020-12-26"},
                 {"Sunday, Dec 27", "2020-12-27"},
                 {"Monday, Dec 28", "2020-12-28"}
               ],
               options
             )
    end

    test "handles Spanish" do
      patient_case = %{"properties" => %{"isolation_start_date" => "2020-12-20"}}

      options = View.exposed_on_select_options(patient_case, locale: "es")

      assert match?(
               [
                 {"Viernes 18 de Dic", "2020-12-18"},
                 {"Sábado 19 de Dic", "2020-12-19"},
                 {"Domingo 20 de Dic", "2020-12-20"},
                 {"Lunes 21 de Dic", "2020-12-21"},
                 {"Martes 22 de Dic", "2020-12-22"},
                 {"Miércoles 23 de Dic", "2020-12-23"},
                 {"Jueves 24 de Dic", "2020-12-24"},
                 {"Viernes 25 de Dic", "2020-12-25"},
                 {"Sábado 26 de Dic", "2020-12-26"},
                 {"Domingo 27 de Dic", "2020-12-27"},
                 {"Lunes 28 de Dic", "2020-12-28"}
               ],
               options
             )
    end
  end
end
