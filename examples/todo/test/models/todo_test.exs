defmodule Todo.TodoTest do
  use Todo.ModelCase

  alias Todo.Todo

  @valid_attrs %{body: "some content", completed: true}
  @invalid_attrs %{}

  test "changeset with valid attributes" do
    changeset = Todo.changeset(%Todo{}, @valid_attrs)
    assert changeset.valid?
  end

  test "changeset with invalid attributes" do
    changeset = Todo.changeset(%Todo{}, @invalid_attrs)
    refute changeset.valid?
  end
end
