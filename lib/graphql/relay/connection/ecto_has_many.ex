defmodule GraphQL.Relay.Connection.Ecto.HasMany do
  @moduledoc """
  Interface between Relay Connections and Ecto.Association.Has relationship.
  In other words, this module allows you to back a Relay Connection with an
  Ecto has_many relationship.
  """
  import Ecto.Query
  @prefix "ectohasmanyconnection:"

  def resolve(query, %{repo: repo} = args) do
    resolve_slice(query, args, %{
      slice_start: 0,
      list_length: connection_count(repo, query)
    })
  end

  def resolve_slice(query, %{repo: repo} = args, meta) do
    before = args[:before]
    a_after = args[:after]
    first = args[:first]
    last = args[:last]

    slice_start = meta[:slice_start] || 0
    list_length = meta[:list_length] || connection_count(repo, query)
    slice_end = slice_start + connection_count(repo, query)
    before_offset = get_offset_with_default(before, list_length)
    after_offset = get_offset_with_default(a_after, -1)
    start_offset = Enum.max([slice_start - 1, after_offset, -1]) + 1
    end_offset = Enum.min([slice_end, before_offset, list_length])

    if first do
      end_offset = Enum.min([end_offset, start_offset + first])
    end

    if last do
      start_offset = Enum.max([start_offset, end_offset - last])
    end

    from_slice = Enum.max([start_offset - slice_start, 0])
    to_slice = connection_count(repo, query) - (slice_end - end_offset) - 1
    slice = case first do
      0 -> []
      _ ->
        Enum.slice(repo.all(query), from_slice..to_slice)
    end

    {edges, _count} = Enum.map_reduce(slice, 0, fn(record, acc) -> {%{ cursor: cursor_for_object_in_connection(record), node: record }, acc + 1} end)

    first_edge = List.first(edges)
    last_edge = List.last(edges)
    lower_bound = a_after && after_offset + 1 || 0
    upper_bound = before && before_offset || list_length

    %{
      edges: edges,
      pageInfo: %{
        startCursor: first_edge && Map.get(first_edge, :cursor) || nil,
        endCursor: last_edge && Map.get(last_edge, :cursor) || nil,
        hasPreviousPage: last && (start_offset > lower_bound) || false,
        hasNextPage: first && (end_offset < upper_bound) || false
      }
    }
  end

  def get_offset_with_default(cursor, default_offset) do
    unless cursor do
      default_offset
    else
      offset = cursor_to_offset(cursor)
      offset || default_offset
    end
  end

  def cursor_to_offset(cursor) do
    case Base.decode64(cursor) do
      {:ok, decoded_cursor} ->
        {int, _} = Integer.parse(String.slice(decoded_cursor, String.length(@prefix)..String.length(decoded_cursor)))
        int
      :error ->
        nil
    end
  end

  def cursor_for_object_in_connection(object) do
    Base.encode64("#{@prefix}#{object.id}")
  end

  def connection_count(repo, query) do
    count_query = from things in query, select: count(things.id)
    repo.one(count_query)
  end
end
