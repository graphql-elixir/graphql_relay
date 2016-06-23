defmodule EctoTest.Repo.Migrations.CreateLetter do
  use Ecto.Migration

  def change do
    create table(:letters) do
      add :letter, :string
      add :second_column, :string
      add :order, :integer
      timestamps
    end

    create table(:numbers) do
      add :number, :integer
      add :letter_id, references(:letters, on_delete: :nothing)
      timestamps
    end
  end
end
