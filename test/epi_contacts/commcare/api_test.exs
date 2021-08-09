defmodule EpiContacts.Commcare.ApiTest do
  use EpiContacts.Test.SimpleCase

  alias EpiContacts.Commcare.Api

  import Mox
  setup :verify_on_exit!

  @test_domain "test-domain"
  @case_id "00000000-ba49-4c43-853f-47b9c6416d2c"

  describe "get_case" do
    test "with successful response, returns :ok tuple with case info" do
      Mox.expect(EpiContacts.HTTPoisonMock, :get, 1, fn url, _headers ->
        assert url ==
                 "https://www.commcarehq.org/a/#{@test_domain}/api/v0.5/case/#{@case_id}/?format=json&child_cases__full=true"

        response_body = File.read!("test/fixtures/commcare/00000000-ba49-4c43-853f-47b9c6416d2c.json")
        {:ok, %{status_code: 200, body: response_body}}
      end)

      assert {:ok, %{"case_id" => @case_id}} = Api.get_case(@case_id, @test_domain)
    end

    test "with unsuccessful response, returns error tuple" do
      Mox.expect(EpiContacts.HTTPoisonMock, :get, 1, fn url, _headers ->
        assert url ==
                 "https://www.commcarehq.org/a/#{@test_domain}/api/v0.5/case/#{@case_id}/?format=json&child_cases__full=true"

        {:ok, %{status_code: 404}}
      end)

      assert {:error, :not_found} = Api.get_case(@case_id, @test_domain)
    end

    test "with error response, returns error tuple" do
      Mox.expect(EpiContacts.HTTPoisonMock, :get, 1, fn url, _headers ->
        assert url ==
                 "https://www.commcarehq.org/a/#{@test_domain}/api/v0.5/case/#{@case_id}/?format=json&child_cases__full=true"

        {:error, :http_timeout}
      end)

      assert {:error, :http_timeout} = Api.get_case(@case_id, @test_domain)
    end
  end

  describe "post_case" do
    test "with successful response, returns :ok" do
      Mox.expect(EpiContacts.HTTPoisonMock, :post, 1, fn url, body, _headers, _opt ->
        assert url == "https://www.commcarehq.org/a/#{@test_domain}/receiver/"
        assert body == "some data"
        response_body = File.read!("test/fixtures/commcare/post-response_success.xml")
        {:ok, %{status_code: 201, body: response_body}}
      end)

      assert :ok == Api.post_case("some data", @test_domain)
    end

    test "with unsuccessful response, returns error tuple containing http response details" do
      Mox.expect(EpiContacts.HTTPoisonMock, :post, 1, fn url, body, _headers, _opt ->
        assert url == "https://www.commcarehq.org/a/#{@test_domain}/receiver/"
        assert body == "some data"
        {:ok, %{status_code: 201, body: "not a success"}}
      end)

      assert {:error, {:commcare_post_error, {:ok, %{status_code: 201, body: "not a success"}}}} ==
               Api.post_case("some data", @test_domain)
    end

    test "with timeout" do
      Mox.expect(EpiContacts.HTTPoisonMock, :post, 1, fn url, body, _headers, _opt ->
        assert url == "https://www.commcarehq.org/a/#{@test_domain}/receiver/"
        assert body == "some data"
        {:error, %HTTPoison.Error{id: nil, reason: :timeout}}
      end)

      assert {:error, :timeout} == Api.post_case("some data", @test_domain)
    end

    test "with error response, returns error tuple containing http error response details" do
      Mox.expect(EpiContacts.HTTPoisonMock, :post, 1, fn url, body, _headers, _opt ->
        assert url == "https://www.commcarehq.org/a/#{@test_domain}/receiver/"
        assert body == "some data"
        {:error, :some_error}
      end)

      assert {:error, :some_error} == Api.post_case("some data", @test_domain)
    end
  end

  describe "post_success?" do
    test "returns true if a checkmark is returned" do
      body = """
      <OpenRosaResponse xmlns="http://openrosa.org/http/response">
        <message nature="submit_success"> √ </message>
      </OpenRosaResponse>
      """

      assert Api.post_success?(body)
    end

    test "returns true even if there are no newlines in the response body (bug fix)" do
      body =
        "<OpenRosaResponse xmlns=\"http://openrosa.org/http/response\"><message nature=\"submit_success\">   √   </message></OpenRosaResponse>"

      assert Api.post_success?(body)
    end

    test "returns true even if there are no spaces around the checkmark" do
      body =
        "<OpenRosaResponse xmlns=\"http://openrosa.org/http/response\"><message nature=\"submit_success\">√</message></OpenRosaResponse>"

      assert Api.post_success?(body)
    end

    test "returns false if the response is not a √" do
      body =
        "<OpenRosaResponse xmlns=\"http://openrosa.org/http/response\"><message nature=\"submit_success\">NOT A CHECKMARK!</message></OpenRosaResponse>"

      refute Api.post_success?(body)
    end

    test "returns false if the response message attribute 'nature' is not 'submit_success'" do
      body =
        "<OpenRosaResponse xmlns=\"http://openrosa.org/http/response\"><message nature=\"submit_UNSUCCESSFUL\">√</message></OpenRosaResponse>"

      refute Api.post_success?(body)
    end

    test "returns false if the xmlns is wrong" do
      body =
        "<OpenRosaResponse xmlns=\"http://WRONG.org/http/response\"><message nature=\"submit_success\">√</message></OpenRosaResponse>"

      refute Api.post_success?(body)
    end
  end
end
