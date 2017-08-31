defmodule SurvedaOnaConnector.Repo.Migrations.CreateSurveys do
  use Ecto.Migration

  def change do
    create table(:surveys) do
      add :name, :string
      add :surveda_id, :integer
      add :ona_id, :integer
      add :project_id, references(:projects, on_delete: :nothing)
      add :last_poll, :utc_datetime
      add :final, :boolean, default: false

      timestamps()
    end
    create index(:surveys, [:project_id])
  end
end
