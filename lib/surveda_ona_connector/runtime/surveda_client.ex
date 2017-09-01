defmodule SurvedaOnaConnector.Runtime.Surveda.Client do
  alias SurvedaOnaConnector.Runtime.Surveda.Client
  defstruct [:base_url, :oauth2_client]

  def new(url, token) do
    oauth2_client = OAuth2.Client.new(token: %OAuth2.AccessToken{access_token: token})
    %Client{base_url: url, oauth2_client: oauth2_client}
  end

  def get_surveys(client, project_id, since) do
    client |> get("http://#{client.base_url}/api/v1/projects/#{project_id}/surveys?state='completed'&since='#{since |> DateTime.to_string}'")
  end

  def get_survey(client, project_id, survey_id) do
    client |> get("http://#{client.base_url}/api/v1/projects/#{project_id}/surveys?id=#{survey_id}")
  end

  def get_questionnaires(client, project_id, survey_id) do
    ids = get_survey(client, project_id, survey_id)["questionnaire_ids"]

    ids |> Enum.map(fn quiz_id ->
      client |> get("http://#{client.base_url}/api/v1/projects/#{project_id}/questionnaires/?id=#{quiz_id}")
    end)
  end

  def get_results(client, project_id, survey_id, since) do
    client |> get("http://#{client.base_url}/api/v1/projects/#{project_id}/surveys/#{survey_id}/results?final=true&_format='json'&since='#{since |> DateTime.to_string}'")
  end

  def get(client, url) do
    {:ok, response} = client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response

    response["data"]
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
