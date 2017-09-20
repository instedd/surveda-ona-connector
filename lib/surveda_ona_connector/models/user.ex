defmodule SurvedaOnaConnector.User do
  use Ecto.Schema
  import Ecto.Changeset
  alias SurvedaOnaConnector.{Repo, Survey}
  alias __MODULE__

  schema "users" do
    field :email, :string
    field :ona_api_token, :string
    has_many :surveys, Survey

    timestamps()
  end

  def changeset(struct, params \\ %{}) do
    struct
    |> cast(params, [:email, :ona_api_token])
    |> validate_required([:email])
    |> unique_constraint(:email)
    |> validate_format(:email, ~r/@/)
  end

  def update(%User{} = user, attrs) do
    user
    |> changeset(attrs)
    |> Repo.update
  end
end
