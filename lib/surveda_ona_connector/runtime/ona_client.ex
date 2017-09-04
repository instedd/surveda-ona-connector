defmodule SurvedaOnaConnector.Runtime.Ona.Client do
  alias SurvedaOnaConnector.Runtime.Ona.Client
  defstruct [:base_url, :oauth2_client]

  def new(url, token) do
    oauth2_client = OAuth2.Client.new(token: token)
    %Client{base_url: url, oauth2_client: oauth2_client}
  end

  def submit_project_form(client, project_id, xls_file) do
    url = "#{client.base_url}/api/v1/projects/#{project_id}/forms"
    client.oauth2_client
    |> OAuth2.Client.post(url, %{xls_file: xls_file})
    |> parse_response
  end

  defp parse_response(response) do
    case response do
      {:ok, response = %{status_code: 200}} ->
        {:ok, response.body}
      {:ok, response} ->
        {:error, response.status_code}
      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, reason}
    end
  end
end
