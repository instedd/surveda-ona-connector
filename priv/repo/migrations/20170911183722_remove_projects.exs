defmodule SurvedaOnaConnector.Repo.Migrations.RemoveProjects do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      remove :project_id
    end
    drop table(:projects)
  end
end
