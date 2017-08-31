defmodule SurvedaOnaConnector.Survey do
  use Ecto.Schema
  import Ecto.Changeset
  alias SurvedaOnaConnector.Survey

  schema "surveys" do
    field :name, :string
    field :surveda_id, :integer
    field :ona_id, :integer
    field :last_poll, :utc_datetime
    field :final, :boolean, default: false

    belongs_to :project, Ask.Project

    timestamps()
  end

  @doc false
  def changeset(%Survey{} = project, attrs) do
    project
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
