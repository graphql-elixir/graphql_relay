if Code.ensure_loaded?(Ecto) do
  defmodule GraphQL.Relay.Connection.Ecto do
    @moduledoc """
    Interface between Relay Connections and Ecto Queries.

    In other words, this module allows you to back a Relay Connection with an
    Ecto query.
    """
    import Ecto.Query
    @prefix "ectoconnection:"

    def resolve(query, %{repo: repo} = args) do
      before = cursor_to_offset(args[:before])
      a_after = cursor_to_offset(args[:after])
      first = args[:first]
      last = args[:last]
      limit = Enum.min([first, last, connection_count(repo, query)])

      if a_after do
        query = from things in query, where: things.id > ^a_after
      end

      if before do
        query = from things in query, where: things.id < ^before
      end

      # Calculate has_next_page/has_prev_page before order_by to avoid group_by
      # requirement
      has_next_page = case first do
        nil -> false
        _ ->
          first_limit = first + 1
          has_more_records_query = from things in query, limit: ^first_limit
          has_more_records_query = from things in has_more_records_query, select: count(things.id)
          repo.one(has_more_records_query) > first
      end

      has_prev_page = case last do
        nil -> false
        _ ->
          last_limit = last + 1
          has_prev_records_query = from things in query, limit: ^last_limit
          has_prev_records_query = from things in has_prev_records_query, select: count(things.id)
          repo.one(has_prev_records_query) > last
      end

      if first do
        query = from things in query, order_by: [asc: things.id], limit: ^limit
      else
        has_next_page = false
      end

      if last do
        query = from things in query, order_by: [desc: things.id], limit: ^limit
      else
        has_prev_page = false
      end

      records = repo.all(query)

      edges = Enum.map(records, fn(record) ->
        %{
          cursor: cursor_for_object_in_connection(record),
          node: record
        }
      end)

      edges = case last do
        nil ->
          edges
        _ ->
          Enum.reverse(edges)
      end

      first_edge = List.first(edges)
      last_edge = List.last(edges)

      %{
        edges: edges,
        pageInfo: %{
          startCursor: first_edge && Map.get(first_edge, :cursor) || nil,
          endCursor: last_edge && Map.get(last_edge, :cursor) || nil,
          hasPreviousPage: has_prev_page,
          hasNextPage: has_next_page
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
      case cursor do
        nil -> nil
        _ ->
          case Base.decode64(cursor) do
            {:ok, decoded_cursor} ->
              {int, _} = Integer.parse(String.slice(decoded_cursor, String.length(@prefix)..String.length(decoded_cursor)))
              int
            :error ->
              nil
          end
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
end
