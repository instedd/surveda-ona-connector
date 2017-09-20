defmodule SurvedaOnaConnector.Repo.Migrations.AddUserIdToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :user_id, references(:users, on_delete: :nothing)
    end
  end
end
