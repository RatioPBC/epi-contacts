defmodule EpiContacts.Commcare.Api do
  @moduledoc """
  This module provides an interface to the Commcare API.
  """
  @timeout 10_000
  @recv_timeout 30_000

  def get_case(case_id, domain) do
    commcare_api_case_url(domain, case_id)
    |> get()
    |> parse_response()
  end

  def post_case(xml_body, domain) do
    xml_body
    |> post(commcare_api_post_url(domain))
    |> parse_response()
  end

  defp get(url) do
    http_client().get(
      url,
      headers()
    )
  end

  defp post(xml_body, url) do
    http_client().post(
      url,
      xml_body,
      headers(),
      timeout: @timeout,
      recv_timeout: @recv_timeout
    )
  end

  defp commcare_api_case_url(commcare_domain, case_id) do
    "https://www.commcarehq.org/a/#{commcare_domain}/api/v0.5/case/#{case_id}/?format=json&child_cases__full=true"
  end

  defp commcare_api_post_url(commcare_domain) do
    "https://www.commcarehq.org/a/#{commcare_domain}/receiver/"
  end

  defp headers do
    [Authorization: "ApiKey #{commcare_api_token()}"]
  end

  defp commcare_api_token, do: Application.fetch_env!(:epi_contacts, :commcare_api_token)
  defp http_client, do: Application.fetch_env!(:epi_contacts, :http_client)

  def post_success?(body) do
    body
    |> Floki.parse_document!()
    |> Floki.find(~S(openrosaresponse[xmlns="http://openrosa.org/http/response"] message[nature="submit_success"]))
    |> Floki.text()
    |> String.trim()
    |> Kernel.==("√")
  end

  defp parse_response({:ok, %{status_code: 201, body: body}} = response) do
    require Logger

    if post_success?(body) do
      :ok
    else
      Logger.warn("bad response from commcare: #{inspect(body)}")
      {:error, {:commcare_post_error, response}}
    end
  end

  defp parse_response({:ok, %{status_code: 200, body: body}}), do: {:ok, Jason.decode!(body)}
  defp parse_response({:ok, %{status_code: 400}}), do: {:error, :commcare_data_error}
  defp parse_response({:ok, %{status_code: 401}}), do: {:error, :commcare_authorization_error}
  defp parse_response({:ok, %{status_code: 403}}), do: {:error, :commcare_forbidden}
  defp parse_response({:ok, %{status_code: 404}}), do: {:error, :not_found}
  defp parse_response({:error, _} = response), do: response
end
