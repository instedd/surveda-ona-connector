defmodule SurvedaOnaConnector.Runtime.Ona.Client do
  alias __MODULE__
  defstruct [:base_url, :oauth2_client]

  def new(url, token) do
    oauth2_client = OAuth2.Client.new(token: %OAuth2.AccessToken{access_token: token, token_type: "Token"})
    %Client{base_url: url, oauth2_client: oauth2_client}
  end

  def submit_project_form(client, project_id, {file_name, file}) do
    url = "#{client.base_url}/api/v1/projects/#{project_id}/forms"
    headers = [{"content-type", "multipart/form-data"}, {"accept", "*/*"}]
    body = {:multipart, [{"xls_file", file, {"form-data", [name: "xls_file", filename: file_name]}, []}]}

    client.oauth2_client
      |> OAuth2.Client.post(url, body, headers)
      |> parse_response
  end

  def submit_respondent_form(client, _survey, json) do
    url = "#{client.base_url}/api/v1/submissions"
    headers = [{"content-type", "application/json"}]

    result = client.oauth2_client
      |> OAuth2.Client.post(url, json, headers)
      |> parse_response
    result
  end

  def delete_all_project_forms(client, project_id) do
    {:ok, forms} = client.oauth2_client
      |> OAuth2.Client.get("http://api.ona.io/api/v1/projects/#{project_id}/forms")
      |> parse_response

    forms |> Enum.map(fn form ->
      client.oauth2_client |> OAuth2.Client.delete(form["url"])
    end)
  end

  defp parse_response(response) do
    case response do
      {:ok, response = %{status_code: 200}} ->
        {:ok, response.body}
      {:ok, response = %{status_code: 201}} ->
        {:ok, response.body}
      {:ok, response} ->
        {:error, response.status_code}
      {:error, %OAuth2.Error{reason: reason}} ->
        {:error, reason}
      {:error, %OAuth2.Response{body: body}} ->
        {:error, body}
    end
  end
end
