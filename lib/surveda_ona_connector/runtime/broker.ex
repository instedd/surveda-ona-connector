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
      # mark_stalled_for_eight_hours_respondents_as_failed()

      # Repo.all(from r in Respondent, where: r.state == "active" and r.timeout_at <= ^now, limit: ^batch_limit_per_minute())
      # |> Enum.each(&retry_respondent(&1))

      # all_running_surveys()
      # |> Enum.filter(&survey_matches_schedule?(&1, now))
      # |> Enum.each(&poll_survey/1)

      {:noreply, state}
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
end
