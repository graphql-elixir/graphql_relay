defmodule Todo.Repo.Migrations.CreateTodo do
  use Ecto.Migration

  def change do
    create table(:todos) do
      add :user_id, references(:users)
      add :text, :string
      add :complete, :boolean, default: false

      timestamps
    end

  end
end
