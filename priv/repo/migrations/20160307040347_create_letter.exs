defmodule EctoTest.Repo.Migrations.CreateLetter do
  use Ecto.Migration

  def change do
    create table(:letters) do
      add :letter, :string
      add :second_column, :string
      timestamps
    end
  end
end
