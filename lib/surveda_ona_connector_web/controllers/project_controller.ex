defmodule SurvedaOnaConnectorWeb.ProjectController do
  alias SurvedaOnaConnector.Runtime.{Broker, Surveda}
  use SurvedaOnaConnectorWeb, :controller
  import Ecto.Query
  plug Guisso.SSO, session_controller: SurvedaOnaConnectorWeb.Coherence.SessionController

  def index(conn, _params) do
    projects = Broker.surveda_client(Coherence.current_user(conn).email)
      |> Surveda.Client.get_projects()

    render(conn, "index.html", projects: projects)
  end

  def show(conn, %{"id" => id}) do
    surveys = Broker.surveda_client(Coherence.current_user(conn).email)
      |> Surveda.Client.get_all_surveys(id)

    surveys_local_ids = SurvedaOnaConnector.Repo.all(from s in SurvedaOnaConnector.Survey, where: s.surveda_project_id == ^id and s.active == true)
      |> Enum.reduce([], &get_surveda_id/2)

    surveys_inactive_ids = SurvedaOnaConnector.Repo.all(from s in SurvedaOnaConnector.Survey, where: s.surveda_project_id == ^id and s.active == false)
      |> Enum.reduce([], &get_surveda_id/2)

    render(conn, "show.html", surveys: surveys, project_id: id, surveys_local_ids: surveys_local_ids, surveys_inactive_ids: surveys_inactive_ids)
  end

  def track_survey(conn, %{"survey_id" => survey_id, "project_id" => project_id, "survey_name" => survey_name}) do
    current_user = Coherence.current_user(conn)
    Broker.insert_or_update_survey(nil, nil, survey_id, project_id, survey_name, current_user.id, nil)

    redirect conn, to: project_path(conn, :show, project_id)
  end

  defp get_surveda_id(survey, acc) do
    acc ++ [survey.surveda_id]
  end
end
