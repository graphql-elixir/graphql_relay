Application.ensure_started(:ecto)
Application.ensure_started(:postgrex)

###
# Setup Ecto
Code.require_file("ecto_repo.exs","./test/support")
Mix.Task.run "ecto.drop", ["--quiet"]
Mix.Task.run "ecto.create", ["--quiet"]
Mix.Task.run "ecto.migrate", ["--quiet"]
EctoTest.Repo.start_link
#
###

ExUnit.start(exclude: [:skip])

# Ecto v2.x
Ecto.Adapters.SQL.Sandbox.mode(EctoTest.Repo, :manual)

defmodule ExUnit.TestHelpers do
  import ExUnit.Assertions

  alias GraphQL.Lang.Parser

  def stringify_keys(map) when is_map(map) do
    Enum.reduce(map, %{}, fn({k, v}, acc) -> Map.put(acc, stringify_key(k), stringify_keys(v)) end)
  end
  def stringify_keys(list) when is_list(list) do
    Enum.map(list, &stringify_keys/1)
  end
  def stringify_keys(x), do: x

  def stringify_key(key) when is_atom(key), do: to_string(key)
  def stringify_key(key), do: key

  def assert_parse(input_string, expected_output, type \\ :ok) do
    assert Parser.parse(input_string) == {type, expected_output}
  end

  def assert_execute({query, schema}, expected_output) do
    assert_execute({query, schema, %{}}, expected_output)
  end

  def assert_execute({query, schema, data}, expected_output) do
    assert_execute({query, schema, data, %{}}, expected_output)
  end

  def assert_execute({query, schema, data, variables}, expected_output) do
    assert_execute({query, schema, data, variables, nil}, expected_output)
  end

  def assert_execute({query, schema, data, variables, operation}, expected_output) do
    assert(GraphQL.execute(schema, query, data, variables, operation) ==
      {:ok, %{data: stringify_keys(expected_output)}})
  end

  def assert_execute_error({query, schema}, expected_output) do
    assert_execute_error({query, schema, %{}}, expected_output)
  end

  def assert_execute_error({query, schema, data}, expected_output) do
    assert GraphQL.execute(schema, query, data) == {:error, %{errors: stringify_keys(expected_output)}}
  end
end
