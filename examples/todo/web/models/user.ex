defmodule Todo.User do
  use Todo.Web, :model

  schema "users" do
    field :name, :string
    field :email, :string
    field :encrypted_password, :string

    has_many :todos, Todo.Todo

    timestamps
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:name, :email, :encrypted_password])
    |> validate_required([:name, :email])
  end

  def todos do
    []
  end
end
