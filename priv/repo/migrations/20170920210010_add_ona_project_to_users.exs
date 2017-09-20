defmodule SurvedaOnaConnector.Repo.Migrations.AddOnaProjectToUsers do
  use Ecto.Migration

  def change do
    alter table(:users) do
      add :ona_project_id, :integer
    end
  end
end
