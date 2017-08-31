defmodule SurvedaOnaConnector.Project do
  use Ecto.Schema
  import Ecto.Changeset
  alias SurvedaOnaConnector.Project

  schema "projects" do
    field :name, :string
    field :surveda_id, :integer
    field :ona_id, :integer
    field :last_poll, :utc_datetime

    timestamps()
  end

  @doc false
  def changeset(%Project{} = project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
