defmodule Todo.Todo do
  use Todo.Web, :model

  schema "todos" do
    belongs_to :user, Todo.User
    field :text, :string
    field :complete, :boolean, default: false

    timestamps
  end

  @doc """
  Creates a changeset based on the `model` and `params`.

  If no params are provided, an invalid changeset is returned
  with no validation performed.
  """
  def changeset(model, params \\ %{}) do
    model
    |> cast(params, [:user_id, :complete, :text])
    |> validate_required([:user_id, :text])
  end
end
