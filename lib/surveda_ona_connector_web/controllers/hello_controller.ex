defmodule SurvedaOnaConnectorWeb.HelloController do
  use SurvedaOnaConnectorWeb, :controller

  def index(conn, _params) do
    render conn, "index.html"
  end
end
