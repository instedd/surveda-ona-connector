defmodule SurvedaOnaConnectorWeb.ProjectController do
  alias SurvedaOnaConnector.Runtime.{Broker, Surveda}
  # alias SurvedaOnaConnector.Runtime.{XLSFormBuilder, Ona, Surveda}
  use SurvedaOnaConnectorWeb, :controller

  def index(conn, _params) do
    surveda_client = Broker.surveda_client()

    # surveda_client
    #   |> Surveda.Client.get_surveys(Broker.environment_variable_named(:surveda_project), %{DateTime.utc_now | month: 1})
    #   |> Enum.each(fn x -> IO.puts "surveys"; IO.inspect x end)

    projects = surveda_client
      |> Surveda.Client.get_projects()
      # |> Enum.each(fn x -> IO.puts "projects"; IO.inspect x end)

    # render conn, "index.html"
    render(conn, "index.html", projects: projects)
  end


  def show(conn, %{"id" => id}) do
    surveda_client = Broker.surveda_client()
    surveys = surveda_client
      |> Surveda.Client.get_surveys(id, %{DateTime.utc_now | month: 1})

    render(conn, "show.html", surveys: surveys)
  end


end
