defmodule EpiContacts.PostContactWorkerTest do
  use EpiContacts.DataCase, async: false

  import Mox
  import ExUnit.CaptureLog

  alias EpiContacts.{HTTPoisonMock, PostContactWorker, Contact}

  setup :set_mox_global
  setup :verify_on_exit!

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

  @valid_job_args %{
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

  describe "enqueue_contacts" do
    setup do
      patient_case = @patient_case

      contact1 = %Contact{
        first_name: "Contact 1",
        phone: "123-456-7890",
        email: "contact1@example.com"
      }

      contact2 = %Contact{
        first_name: "Contact 2",
        phone: "123-456-7890",
        email: "contact2@example.com"
      }

      [
        patient_case: patient_case,
        contacts: [contact1, contact2]
      ]
    end

    test "it posts all of the contacts associated with a patient case and contacts", %{
      patient_case: patient_case,
      contacts: contacts
    } do
      assert :ok = PostContactWorker.enqueue_contacts(%{patient_case: patient_case, contacts: contacts})

      all_jobs = all_enqueued(worker: PostContactWorker)
      assert length(all_jobs) == 2
      [job1, job2] = all_jobs
      assert @patient_case = job1.args["patient_case"]
      assert @patient_case = job2.args["patient_case"]

      assert %{"email" => "contact1@example.com", "first_name" => "Contact 1"} = job2.args["contact"]
      assert %{"email" => "contact2@example.com", "first_name" => "Contact 2"} = job1.args["contact"]
    end
  end

  describe "perform" do
    test "enqueues the arguments on a successful post" do
      successful_http_post()
      assert :ok = perform_job(PostContactWorker, @valid_job_args)
    end

    test "returns a failure if the response is a 201 without the correct response" do
      http_post_201_response_with_bad_body()

      assert capture_log(fn ->
               assert {:error, {:commcare_post_error, {:ok, %{body: "incorrect body", status_code: 201}}}} =
                        perform_job(PostContactWorker, @valid_job_args)
             end) =~ "bad response from commcare"
    end

    test "snoozes upload if there's a timeout" do
      mock_timeout()
      assert {:snooze, 60} == perform_job(PostContactWorker, @valid_job_args)
      mock_timeout()
      assert {:snooze, 180} == perform_job(PostContactWorker, @valid_job_args, attempt: 2)
    end
  end

  # ====================================================================================================================

  defp successful_http_post do
    expect(HTTPoisonMock, :post, fn _url, _body, _headers, _opts ->
      body = File.read!("test/fixtures/commcare/post-response_success.xml")
      {:ok, %{status_code: 201, body: body}}
    end)
  end

  defp mock_timeout do
    expect(HTTPoisonMock, :post, fn _url, _body, _headers, _opts ->
      {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
    end)
  end

  defp http_post_201_response_with_bad_body do
    expect(HTTPoisonMock, :post, fn _url, _body, _headers, _opts ->
      {:ok, %{status_code: 201, body: "incorrect body"}}
    end)
  end
end
