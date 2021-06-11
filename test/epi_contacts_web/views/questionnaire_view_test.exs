defmodule EpiContactsWeb.QuestionnaireViewTest do
  use EpiContactsWeb.ConnCase, async: true

  alias EpiContactsWeb.QuestionnaireView, as: View

  describe "format" do
    test "it formats the date for the user" do
      assert View.format(~D[2020-04-15]) == "Wednesday, April 15"
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

      html = html_for(patient_case)

      assert_content(html)
      assert Floki.text(html) =~ gettext("If you have already spoken with us...")

      rows_text =
        html
        |> Floki.find("tbody tr")
        |> Floki.text()

      assert rows_text =~ "J.D."
      assert rows_text =~ "*** *** 6666"
    end

    test "only displays copy" do
      html = html_for(%{"child_cases" => %{}})

      assert_content(html)
    end

    defp assert_content(html) do
      assert Floki.text(html) =~ gettext("Use this questionnaire to add people you haven’t told us about.")
    end

    defp html_for(patient_case) do
      patient_case
      |> View.existing_contacts_section()
      |> Phoenix.HTML.safe_to_string()
      |> Floki.parse_fragment!()
    end
  end

  describe "exposed_on_select_options/1" do
    test "doesn't return future dates" do
      patient_case = %{"properties" => %{"isolation_start_date" => "2021-01-04"}}

      options = View.exposed_on_select_options(patient_case, ~D[2021-01-06])
      assert Enum.count(options) == 5

      patient_case = %{"properties" => %{"isolation_start_date" => "2020-12-20"}}

      options = View.exposed_on_select_options(patient_case)
      assert Enum.count(options) == 11
    end
  end
end
