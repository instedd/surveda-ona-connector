defmodule SurvedaOnaConnector.Runtime.Surveda.Client do
  alias SurvedaOnaConnector.Runtime.Surveda.Client
  alias SurvedaOnaConnector.Logger
  defstruct [:base_url, :oauth2_client]

  def new(url, user_email) do
    client = OAuth2.Client.new([
      strategy: OAuth2.Strategy.ClientCredentials, # default strategy is AuthCode
      client_id: Application.get_env(:alto_guisso, :client_id),
      client_secret: Application.get_env(:alto_guisso, :client_secret),
      token_url: "#{Application.get_env(:alto_guisso, :base_url)}/oauth2/token",
      params: %{scope: "app=#{URI.parse(url).host} user=#{user_email} token_type=bearer"}
    ])

    client = OAuth2.Client.get_token!(client)

    if client.token.access_token == nil do
      Logger.error "Error obtaining guisso token: #{client}"
      raise "401"
    end

    %Client{base_url: url, oauth2_client: client}
  end

  def get_projects(client) do
    url = "#{client.base_url}/api/v1/projects/"

    client |> get(url)
  end

  def get_surveys(client, project_id, since) do
    url = "#{client.base_url}/api/v1/projects/#{project_id}/surveys?#{URI.encode_query(state: :completed, since: since)}"

    client |> get(url)
  end

  def get_all_surveys(client, project_id) do
    url = "#{client.base_url}/api/v1/projects/#{project_id}/surveys"

    client |> get(url)
  end

  def get_survey(client, project_id, survey_id) do
    url = "#{client.base_url}/api/v1/projects/#{project_id}/surveys/#{survey_id}"

    client |> get(url)
  end

  def get_questionnaires(client, project_id, survey_id) do
    %{"questionnaire_ids" => ids} = get_survey(client, project_id, survey_id)

    ids |> Enum.map(fn quiz_id ->
      url = "#{client.base_url}/api/v1/projects/#{project_id}/questionnaires/#{quiz_id}"
      client |> get(url)
    end)
  end

  def get_results(client, project_id, survey_id, since) do
    query = case since do
      nil -> %{final: true, format: :json}
      _   -> %{final: true, format: :json, since: since}
    end

    url = "#{client.base_url}/api/v1/projects/#{project_id}/surveys/#{survey_id}/respondents/results?#{URI.encode_query(query)}"
    client |> get(url)
  end

  def get(client, url) do
    {:ok, response} = client.oauth2_client
    |> OAuth2.Client.get(url)
    |> parse_response
    response
  end

  defp parse_response(response) do
    case response do
      {:ok, %{status_code: 200, body: %{"data" => data}}} ->
        {:ok, data}
      {:ok, response} ->
        {:error, response.status_code}
      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
