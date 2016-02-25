defmodule GraphQL.Relay do
  @moduledoc """
  Elixir library containing helpers for making a GraphQL server Relay compliant.
  """

  @spec resolve_maybe_thunk(fun | map) :: %{}
  def resolve_maybe_thunk(thing_or_thunk) do
    if Kernel.is_function(thing_or_thunk) do
      thing_or_thunk.()
    else
      thing_or_thunk
    end
  end
end
