defmodule Todo.User do
  use Todo.Web, :model

  schema "users" do
    field :name, :string
    field :email, :string
    field :encrypted_password, :string

    has_many :todos, Todo.Todo

    timestamps
  end

  @required_fields ~w(name email)
  @optional_fields ~w(encrypted_password)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end

  def todos do
    []
  end
end
