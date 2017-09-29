defmodule SurvedaOnaConnector.Survey do
  use Ecto.Schema
  import Ecto.Changeset
  alias __MODULE__

  schema "surveys" do
    field :name, :string
    field :surveda_id, :integer
    field :surveda_project_id, :integer
    field :ona_id, :integer
    field :last_poll, :utc_datetime
    field :active, :boolean, default: true
    field :ona_name, :string
    belongs_to :user, SurvedaOnaConnector.User

    timestamps()
  end

  @doc false
  def changeset(%Survey{} = survey, attrs) do
    survey
    |> cast(attrs, [:name, :surveda_id, :surveda_project_id, :ona_id, :last_poll, :active, :user_id, :ona_name])
    |> validate_required([:name, :surveda_id, :surveda_project_id])
  end
end
