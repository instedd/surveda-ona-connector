defmodule SurvedaOnaConnector.Repo.Migrations.RenameSurveyFields do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :surveda_project_id, :integer
    end
    rename table(:surveys), :final, to: :active
  end
end
