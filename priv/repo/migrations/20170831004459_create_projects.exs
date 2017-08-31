defmodule SurvedaOnaConnector.Repo.Migrations.CreateProjects do
  use Ecto.Migration

  def change do
    create table(:projects) do
      add :name, :string
      add :surveda_id, :integer
      add :ona_id, :integer
      add :last_poll, :utc_datetime

      timestamps()
    end
  end
end
