defmodule SurvedaOnaConnector.Repo.Migrations.AddOnaNameToSurveys do
  use Ecto.Migration

  def change do
    alter table(:surveys) do
      add :ona_name, :string
    end
  end
end
