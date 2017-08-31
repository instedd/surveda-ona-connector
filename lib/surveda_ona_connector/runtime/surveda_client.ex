defmodule Surveda.Client do
  alias Surveda.Client
  defstruct [:base_url, :oauth2_client]

  def new(url, token) do
    oauth2_client = OAuth2.Client.new(token: token)
    %Client{base_url: url, oauth2_client: oauth2_client}
  end

  def get_surveys(client, project_id, since) do
    url = "#{client.base_url}/api/v1/projects/#{project_id}/surveys?state='completed'&since='#{since |> DateTime.to_string}}'"
    client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response
  end

  def get_results(client, project_id, survey_id since) do
    url = "#{client.base_url}/api/v1/projects/#{project_id}/surveys/#{survey_id}/results?final=true&_format='json'&since='#{since |> DateTime.to_string}}'"
    client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response
  end

  defp parse_response(response) do
    case response do
      {:ok, response = %{status_code: 200}} ->
        {:ok, Poison.decode!(response.body)}
      {:ok, response} ->
        {:error, response.status_code}
      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
