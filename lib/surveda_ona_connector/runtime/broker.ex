defmodule SurvedaOnaConnector.Runtime.Broker do
  use GenServer
  import Ecto.Query
  import Ecto
  alias SurvedaOnaConnector.{Repo, Logger}
  # Survey, Questionnaire, Respondent, Response

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

  def handle_info(:poll, state, now) do
    try do
      # get last run datetime

      running_surveys_since(now)
      |> Enum.each(&poll_survey/1)

      # poll old surveys for new results and mark them as done

      # update last run datetime

      {:noreply, state}
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
  end

  def handle_info(:poll, state) do
    handle_info(:poll, state, DateTime.utc_now)
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  def handle_call(:poll, _from, state) do
    handle_info(:poll, state)
    {:reply, :ok, state}
  end

  defp running_surveys_since(datetime) do
    surveda_client = Surveda.Client.new(environment_variable_named(:surveda_host),environment_variable_named(:surveda_api_token))

    surveda_client |> Surveda.Client.get_surveys(environment_variable_named(:surveda_project),
        datetime)
  end

  defp results_since(survey_id, datetime) do
    surveda_client = Surveda.Client.new(environment_variable_named(:surveda_host),environment_variable_named(:surveda_api_token))

    surveda_client |> Surveda.Client.get_results(environment_variable_named(:surveda_project), survey_id,
        datetime)

    conn = get conn, project_survey_respondents_results_path(conn, :results, survey.project.id, survey.id, %{"offset" => "0", "_format" => "csv", "since" => Timex.format!(Timex.shift(Timex.now, hours: 2), "%FT%T%:z", :strftime)})

  end

  defp ona_forms do
    ona_client = Ona.Client.new(environment_variable_named(:ona_host),environment_variable_named(:ona_api_token))

    forms = ona_client |> Ona.Client.get_forms(environment_variable_named(:ona_project))
  end

  defp poll_survey(%{id: survey_id}, datetime) do
    try do
      # store surveda survey id with corresponding ona form id

      # results = results_since(survey_id, datetime)

      # build XLSForm
      # push to ona
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

  def environment_variable_named(name) do
    case Application.get_env(:ask, SurvedaOnaConnector.Runtime.Broker)[name] do
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
end
