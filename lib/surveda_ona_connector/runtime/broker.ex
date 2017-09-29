defmodule SurvedaOnaConnector.Runtime.Broker do
  use GenServer
  import Ecto.Query
  import Ecto.Changeset
  alias SurvedaOnaConnector.{Repo, Logger, Survey, User}
  alias SurvedaOnaConnector.Runtime.{XLSFormBuilder, Ona, Surveda}

  @poll_interval :timer.minutes(20)
  @server_ref {:global, __MODULE__}

  def server_ref, do: @server_ref

  def start_link do
    GenServer.start_link(__MODULE__, [], name: @server_ref)
  end

  # Makes the borker performs a poll on the surveys.
  # This method is intended to be used by tests.
  def poll do
    GenServer.call(@server_ref, :poll)
  end

  def init(_args) do
    :timer.send_after(1000, :poll)
    Logger.info "Broker started."
    {:ok, nil}
  end

  def handle_info(:poll, state) do
    try do
      from(s in Survey, where: s.active == true)
      |> preload(:user)
      |> Repo.all()
      |> Enum.each(fn survey ->
        IO.inspect(survey)
        IO.inspect(survey.user)
        client = surveda_client(survey.user.email)

        if survey.ona_id do
          survey
        else
          survey
          |> start_tracking_survey(client)
        end
        |> poll_survey(client)
      end)

    rescue
      e ->
        if Mix.env == :test do
          IO.inspect e
          IO.inspect System.stacktrace()
          raise e
        end
        Logger.error "Error occurred while polling surveda: #{inspect e} #{inspect System.stacktrace}"
    after
      :timer.send_after(@poll_interval, :poll)
    end
    {:noreply, state}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def handle_call(:poll, _from, state) do
    handle_info(:poll, state)
    {:reply, :ok, state}
  end

  def surveda_client(user_email) do
    Surveda.Client.new(environment_variable_named(:surveda_host), user_email)
  end

  def running_surveys_since(client, project_id, datetime) do
    client |> Surveda.Client.get_surveys(project_id, datetime)
  end

  def results_since(client, project_id, survey_id, datetime) do
    client |> Surveda.Client.get_results(project_id, survey_id, datetime)
  end

  def ona_client(ona_api_token) do
    Ona.Client.new(environment_variable_named(:ona_host),ona_api_token)
  end

  def submit_ona_form(client, xls_form, ona_project_id) do
    client |> Ona.Client.submit_project_form(ona_project_id, xls_form)
  end

  def submit_respondent_form(client, survey, json) do
    client |> Ona.Client.submit_respondent_form(survey, json)
  end

  def delete_all_project_forms do
    ona_client(environment_variable_named(:ona_api_token)) |> Ona.Client.delete_all_project_forms(environment_variable_named(:ona_project))
    :ok
  end

  def insert_or_update_survey(survey, ona_id, survey_id, project_id, survey_name, user_id, ona_name) do
    changeset = Survey.changeset(survey || %Survey{}, %{ona_id: ona_id, surveda_id: survey_id, surveda_project_id: project_id, name: survey_name, ona_name: ona_name, last_poll: nil})

    changeset = case user_id do
      nil -> changeset
      _   -> cast(changeset, %{user_id: user_id}, [:user_id])
    end

    if survey do
      Repo.update!(changeset)
    else
      Repo.insert!(changeset)
    end
  end

  def start_tracking_survey(%{:surveda_id => survey_id, :surveda_project_id => project_id, :name => survey_name}, surveda_client) do
    try do
      # query questionnaires
      questionnaires = surveda_client |> Surveda.Client.get_questionnaires(project_id, survey_id)

      # build xlsform
      builder = questionnaires
      |> Enum.reduce(XLSFormBuilder.new("#{ona_valid_filename(survey_name)}.xlsx"), fn(quiz, builder) ->
        builder |> XLSFormBuilder.add_questionnaire(quiz)
      end)

      xls_form = builder |> XLSFormBuilder.build()

      # submit form
      survey  = Survey |> Repo.get_by(surveda_id: survey_id)
      survey_user = User |> Repo.get_by(id: survey.user_id)

      {:ok, ona_response} = ona_client(survey_user.ona_api_token) |> submit_ona_form(xls_form, survey_user.ona_project_id)

      insert_or_update_survey(survey, ona_response["formid"], survey_id, project_id, survey_name, nil, ona_response["id_string"])
    rescue
      e ->
        if Mix.env == :test do
          IO.inspect e
          IO.inspect System.stacktrace()
          raise e
        end
        Logger.error "Error occurred while polling survey (id: #{survey_id}): #{inspect e} #{inspect System.stacktrace}"
    end
  end

  defp poll_survey(survey, client) do
    try do
      results = client
      |> results_since(survey.surveda_project_id, survey.surveda_id, survey.last_poll)

      respondents = results["respondents"]

      if !Enum.empty?(respondents) do
        last_updated_at = respondents |> Enum.max_by(&Map.get(&1,"updated_at")) |> Map.get("updated_at")

        changeset = Survey.changeset(survey, %{last_poll: last_updated_at})
        Repo.update!(changeset)

        respondents |> Enum.each(&send_respondent_to_ona(&1, survey))
      else
        updated_survey = Surveda.Client.get_survey(client, survey.surveda_project_id, survey.surveda_id)

        if updated_survey["state"] == "terminated" do
          survey
          |> Survey.changeset(%{active: false})
          |> Repo.update!
        end
      end
    rescue
      e ->
        if Mix.env == :test do
          IO.inspect e
          IO.inspect System.stacktrace()
          raise e
        end
        Logger.error "Error occurred while polling survey (id: #{survey.id}): #{inspect e} #{inspect System.stacktrace}"
    end
  end

  def environment_variable_named(name) do
    case Application.get_env(:surveda_ona_connector, SurvedaOnaConnector.Runtime.Broker)[name] do
      {:system, env_var} ->
        System.get_env(env_var)
      {:system, env_var, default} ->
        env_value = System.get_env(env_var)
        if env_value do
          env_value
        else
          default
        end
      value -> value
    end
  end

  def send_respondent_to_ona(respondent, survey) do
    ona_respondent = transform_respondent_into_ona_form(respondent)

    json = %{"id": survey.ona_name, "submission": ona_respondent}

    survey_user = User |> Repo.get_by(id: survey.user_id)
    #TODO: If it returns error, catch it and save the last ok respondent as the timestamp of the last
    {:ok, _ona_response} = ona_client(survey_user.ona_api_token) |> submit_respondent_form(survey, json)
  end

  def transform_respondent_into_ona_form(respondent) do
    responses = respondent["responses"]

    transformed_responses = responses |> Enum.reduce(%{}, &transform_response/2)

    transformed_responses
  end

  def transform_response(response, acc) do
    Map.put(acc, response["name"], response["value"])
  end

  def ona_valid_filename(survey_name) do
    (survey_name || "Untitled Survey")
    |> String.replace(~r/ ([a-z])/, "_\\1")
    |> String.replace(" ", "")
    |> Macro.underscore()
  end
end
