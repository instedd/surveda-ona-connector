defmodule SurvedaOnaConnectorWeb.ProjectController do
  alias SurvedaOnaConnector.Runtime.{Broker, Surveda}
  # alias SurvedaOnaConnector.Runtime.{XLSFormBuilder, Ona, Surveda}
  use SurvedaOnaConnectorWeb, :controller

  def index(conn, _params) do
    projects = Broker.surveda_client()
      |> Surveda.Client.get_projects()

    render(conn, "index.html", projects: projects)
  end


  def show(conn, %{"id" => id}) do
    surveys = Broker.surveda_client()
      |> Surveda.Client.get_all_surveys(id)

    render(conn, "show.html", surveys: surveys, project_id: id)
  end

  def track_survey(conn, %{"survey_id" => survey_id, "project_id" => project_id, "survey_name" => survey_name}) do
    Broker.start_tracking_survey(%{"id" => survey_id, "project_id" => project_id, "name" => survey_name})

    redirect conn, to: project_path(conn, :show, project_id)
  end
end
