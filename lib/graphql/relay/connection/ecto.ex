if Code.ensure_loaded?(Ecto) do
  defmodule GraphQL.Relay.Connection.Ecto do
    @moduledoc """
    Interface between Relay Connections and Ecto. This module allows you to
    back a Relay Connection with an Ecto query.

    ## Example

    A Relay connection starts with a connection definition. For example, a
    `user` can have many `todos` (see code comments):

    ```elixir
    %ObjectType{
      name: "User",
      description: "The user",
      fields: %{
        id: Node.global_id_field("user"),
        name: %{type: %String{}},
        email: %{type: %String{}},
        todos: %{
          type: Todo.connection[:connection_type],
          description: "The todos this user owns",
          args: Map.merge(
            %{status: %{type: %String{}, defaultValue: "any"}},
            Connection.args
          ),
          resolve: fn(user, args, _ctx) ->
            # Here we prepare our Ecto query
            query = Ecto.assoc(user, :todos)
            query = case args do
              %{status: "active"} -> from things in query, where: things.complete == false
              %{status: "completed"} -> from things in query, where: things.complete == true
              _ -> query
            end
            # Here we resolve the connection using our Ecto Connection module,
            # passing it the Ecto Repo we want to query. The `resolve/3` function
            # will execute the query and return the results in the form Relay
            # requires.
            Connection.Ecto.resolve(Repo, query, args)
          end
        },
      },
      interfaces: [Root.node_interface]
    }
    ```
    For a full example see https://github.com/graphql-elixir/graphql_relay/blob/master/examples/todo/web/graphql/user.ex
    """
    import Ecto.Query
    @prefix "ectoconnection:"

    @doc """
    WARNING: this function signature is deprecated. Use `resolve/3`.
    """
    def resolve(query, %{repo: repo} = args) do
      # Emit deprecation warning once we hit >= v0.6 per RELEASE.md#Deprecations
      # :elixir_errors.warn __ENV__.line, __ENV__.file, "Use of `GraphQL.Relay.Connection.Ecto.resolve/2` is deprecated! Use `GraphQL.Relay.Connection.Ecto.resolve/3`."
      resolve(repo, query, args)
    end

    @doc """
    Pass in an Ecto.Repo, an Ecto.Query, and Relay args to have the query
    executed and results returned in the format Relay requires.

    If you wish to have the results ordered by some field other than `id`,
    use `ordered_by` and `ordered_by_direction`.

    Example for returning data in reverse chronological order (newest first)
    like you would do for a page listing blog posts:

      args = %{
        first: 10,
        ordered_by: :inserted_at,
        ordered_by_direction: :desc
      }

    Your GraphQL resolve function for the connection will look something like:

      resolve: fn(blog, args, _ctx) ->
        # Order by desc inserted_at
        args = Map.merge(args, %{ordered_by: :inserted_at, ordered_by_direction: :desc})
        query = Ecto.assoc(blog, :posts)
        GraphQL.Relay.Connection.Ecto.resolve(Repo, query, args)
      end
    """
    defp expr({{:., _, [{:&, _, [idx]}, field]}, _, []}, sources, _query) when is_atom(field) do
      {_, name, _} = elem(sources, idx)
      "#{name}.#{quote_name(field)}"
    end
    def resolve(repo, query, args \\ %{}) do
      before = cursor_to_offset(args[:before])
      # `after` is a keyword http://elixir-lang.org/docs/master/elixir/Kernel.SpecialForms.html#try/1
      a_after = cursor_to_offset(args[:after])
      first = args[:first]
      last = args[:last]

      # Deprecation messages
      # Emit deprecation warning once we hit >= v0.7 per RELEASE.md#Deprecations
      # case args do
      #   %{ordered_by_direction: _} ->
      #     :elixir_errors.warn __ENV__.line, __ENV__.file, "Use of :ordered_by_direction in args is deprecated as it's no longer needed! Use `Ecto.Query.order_by`."
      #   %{ordered_by: _} ->
      #     :elixir_errors.warn __ENV__.line, __ENV__.file, "Use of :ordered_by in args is deprecated as it's no longer needed! Use `Ecto.Query.order_by`."
      # end
      IO.inspect query.order_bys
      ordered_by_direction = case query.order_bys do
        [] -> get_ordered_by_direction(args[:ordered_by_direction] || :asc)
        [%Ecto.Query.QueryExpr{} = query_expr] ->
          case query_expr.expr do
            [asc: _] -> :asc
            [desc: _] -> :desc
          end
      end
      IO.inspect ordered_by_direction
      ordered_by_property = case query.order_bys do
        [] ->
          args[:ordered_by] || :id
        [%Ecto.Query.QueryExpr{expr: [asc: {{:., _, [{:&, [], [idx]}, field]}, [], []}]}] ->
          field
        [%Ecto.Query.QueryExpr{expr: [desc: {{:., _, [{:&, [], [idx]}, field]}, [], []}]}] ->
          field
      end
      IO.inspect ordered_by_property
      opposite_ordered_by_direction = if ordered_by_direction == :asc, do: :desc, else: :asc
      limit = Enum.min([first, last, connection_count(repo, query)])

      query = if a_after do
        case ordered_by_direction do
          :asc ->
            query |> where([a], field(a, ^ordered_by_property) > ^a_after)
          :desc ->
            query |> where([a], field(a, ^ordered_by_property) < ^a_after)
        end
      else
        query
      end

      query = if before do
        case ordered_by_direction do
          :asc ->
            query |> where([a], field(a, ^ordered_by_property) < ^before)
          :desc ->
            query |> where([a], field(a, ^ordered_by_property) > ^before)
        end
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
        case query.order_bys do
          [] ->
            sort_values = Keyword.new([{ordered_by_direction, ordered_by_property}])
            query |> order_by(^sort_values) |> limit(^limit)
          [%Ecto.Query.QueryExpr{} = query_expr] ->
            query |> limit(^limit)
        end
      else
        query
      end

      query = if last do
        case query.order_bys do
          [] ->
            sort_values = Keyword.new([{opposite_ordered_by_direction, ordered_by_property}])
            query |> order_by(^sort_values) |> limit(^limit)
          [%Ecto.Query.QueryExpr{} = query_expr] ->
            # TODO: Update order_by direction to opposite direction
            query |> limit(^limit)
        end
      else
        query
      end

      records = repo.all(query)

      edges = Enum.map(records, fn(record) ->
        %{
          cursor: cursor_for_object_in_connection(record, ordered_by_property),
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
          string = String.slice(decoded_cursor, String.length(@prefix)..String.length(decoded_cursor))
          case Ecto.DateTime.cast(string) do
            {:ok, date} -> date
            :error -> string
          end
        :error ->
          nil
      end
    end

    def cursor_for_object_in_connection(object, property \\ :id) do
      prop = case Map.get(object, property) do
        %Ecto.DateTime{} = date_time -> Ecto.DateTime.to_iso8601(date_time)
        prop -> to_string(prop)
      end

      Base.encode64("#{@prefix}#{prop}")
    end

    def connection_count(repo, query) do
      query = make_query_countable(query)
      count_query = from things in query, select: count(things.id)
      repo.one(count_query)
    end

    defp get_ordered_by_direction(value) when value in [:asc, :desc] do
      value
    end

    defp make_query_countable(query) do
      query
      |> remove_order
      |> remove_preload
      |> remove_select
    end

    # Remove order by if it exists so that we avoid `field X in "order_by"
    # does not exist in the model source in query`
    defp remove_order(query) do
      Ecto.Query.exclude(query, :order_by)
    end

    # Remove preload if it exists so that we avoid "the binding used in `from`
    # must be selected in `select` when using `preload` in query`"
    defp remove_preload(query) do
      Ecto.Query.exclude(query, :preload)
    end

    # Remove select if it exists so that we avoid `only one select
    # expression is allowed in query` Ecto exception
    defp remove_select(query) do
      Ecto.Query.exclude(query, :select)
    end
  end
else
  defmodule GraphQL.Relay.Connection.Ecto do
    def resolve(_, _) do
      raise RuntimeError, message: """
      Ecto not available. Make sure Ecto is installed as a dependency of your
      application.
      """
    end
  end
end
