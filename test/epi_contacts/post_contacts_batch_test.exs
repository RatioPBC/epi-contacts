defmodule EpiContacts.PostContactsBatchTest do
  use EpiContacts.DataCase, async: true

  import ExUnit.CaptureLog
  import Mox
  setup :verify_on_exit!

  alias EpiContacts.{HTTPoisonMock, PostContactsBatch}

  @patient_case %{
    "case_id" => "00000000-8434-4475-b111-bb3a902b398b",
    "owner_id" => "owner",
    "domain" => "domain",
    "properties" => %{
      "date_tested" => "2020-05-13",
      "dob" => "1987-05-06",
      "domain" => "ny-state-covid19",
      "first_name" => "first name",
      "last_name" => "last name",
      "owner_id" => "000000009299465ab175357b95b89e7c",
      "phone_home" => "4544454555"
    }
  }

  @valid_job_args %Oban.Job{
    args: %{
      "patient_case" => @patient_case,
      "contact" => %{
        "contact_id" => "012345-abcde",
        "email" => "contact1@example.com",
        "id" => "id-1",
        "exposed_on" => "2020-11-04",
        "first_name" => "Contact 1",
        "last_name" => "last name",
        "phone" => "123-456-7890"
      }
    }
  }

  describe "process/1" do
    test "posts to CommCare" do
      stub_post_to_commcare()
      assert :ok = PostContactsBatch.process(@valid_job_args)
    end

    test "returns a failure if the response is a 201 without the correct response" do
      stub_post_201_response_with_bad_body()

      assert capture_log(fn ->
               assert {:error, {:commcare_post_error, {:ok, %{body: "incorrect body", status_code: 201}}}} =
                        PostContactsBatch.process(@valid_job_args)
             end) =~ "bad response from commcare"
    end
  end

  defp stub_post_to_commcare do
    expect(HTTPoisonMock, :post, fn _url, _body, _headers, _opts ->
      body = File.read!("test/fixtures/commcare/post-response_success.xml")
      {:ok, %{status_code: 201, body: body}}
    end)
  end

  defp stub_post_201_response_with_bad_body do
    expect(HTTPoisonMock, :post, fn _url, _body, _headers, _opts ->
      {:ok, %{status_code: 201, body: "incorrect body"}}
    end)
  end
end
