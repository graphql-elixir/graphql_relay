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
      # `after` is a keyword http://elixir-lang.org/docs/master/elixir/Kernel.SpecialForms.html#try/1
      a_after = cursor_to_offset(args[:after])
      first = args[:first]
      last = args[:last]
      limit = Enum.min([first, last, connection_count(repo, query)])

      query = if a_after do
        from things in query, where: things.inserted_at > ^a_after
      else
        query
      end

      query = if before do
        from things in query, where: things.inserted_at < ^before
      else
        query
      end

      # Calculate has_next_page/has_prev_page before order_by to avoid group_by requirement
      has_next_page = case first do
        nil -> false
        _ ->
          first_limit = first + 1
          has_more_records_query = make_query_countable(from things in query, limit: ^first_limit)
          has_more_records_query = from things in has_more_records_query, select: count(things.id)
          repo.one(has_more_records_query) > first
      end

      has_prev_page = case last do
        nil -> false
        _ ->
          last_limit = last + 1
          has_prev_records_query = make_query_countable(from things in query, limit: ^last_limit)
          has_prev_records_query = from things in has_prev_records_query, select: count(things.id)
          repo.one(has_prev_records_query) > last
      end

      query = if first do
        from things in query, order_by: [asc: things.inserted_at], limit: ^limit
      else
        query
      end

      query = if last do
        from things in query, order_by: [desc: things.inserted_at], limit: ^limit
      else
        query
      end

      records = repo.all(query)

      edges = Enum.map(records, fn(record) ->
        %{
          cursor: cursor_for_object_in_connection(record),
          node: record
        }
      end)

      edges = case last do
        nil -> edges
        _ -> Enum.reverse(edges)
      end

      first_edge = List.first(edges)
      last_edge = List.last(edges)

      %{
        edges: edges,
        pageInfo: %{
          startCursor: first_edge && Map.get(first_edge, :cursor),
          endCursor: last_edge && Map.get(last_edge, :cursor),
          hasPreviousPage: has_prev_page,
          hasNextPage: has_next_page
        }
      }
    end

    def cursor_to_offset(nil), do: nil
    def cursor_to_offset(cursor) do
      case Base.decode64(cursor) do
        {:ok, decoded_cursor} ->
          date_string = String.slice(decoded_cursor, String.length(@prefix)..String.length(decoded_cursor))
          case Ecto.DateTime.cast(date_string) do
            {:ok, date} -> date
            _ -> nil
          end
        :error ->
          nil
      end
    end

    def cursor_for_object_in_connection(object) do
      date_string = Ecto.DateTime.to_iso8601(object.inserted_at)
      Base.encode64("#{@prefix}#{date_string}")
    end

    def connection_count(repo, query) do
      query = make_query_countable(query)
      count_query = from things in query, select: count(things.id)
      repo.one(count_query)
    end

    defp make_query_countable(query) do
      query
      |> remove_select
      |> remove_order
    end

    # Remove select if it exists so that we avoid `only one select
    # expression is allowed in query` Ecto exception
    defp remove_select(query) do
      Ecto.Query.exclude(query, :select)
    end

    # Remove order by if it exists so that we avoid `field X in "order_by"
    # does not exist in the model source in query`
    defp remove_order(query) do
      Ecto.Query.exclude(query, :order_by)
    end
  end
end
