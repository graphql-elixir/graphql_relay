defmodule Todo.Todo do
  use Todo.Web, :model

  schema "todos" do
    belongs_to :user, Todo.User
    field :text, :string
    field :complete, :boolean, default: false

    timestamps
  end

  @required_fields ~w(user_id text)
  @optional_fields ~w(complete)

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ :empty) do
    model
    |> cast(params, @required_fields, @optional_fields)
  end
end
