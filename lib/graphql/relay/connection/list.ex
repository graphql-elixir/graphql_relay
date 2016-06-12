defmodule GraphQL.Relay.Connection.List do
  @prefix "arrayconnection:"

  def resolve(data), do: resolve(data, %{})
  def resolve(data, args) do
    resolve_slice(data, args, %{
      slice_start: 0,
      list_length: length(data)
    })
  end

  def resolve_slice(records, args, meta) do
    before = args[:before]
    a_after = args[:after]
    first = args[:first]
    last = args[:last]
    slice_start = meta[:slice_start] || 0
    list_length = meta[:list_length] || length(records)
    slice_end = slice_start + length(records)
    before_offset = cursor_to_offset(before, list_length)
    after_offset = cursor_to_offset(a_after, -1)
    start_offset = Enum.max([slice_start - 1, after_offset, -1]) + 1
    end_offset = Enum.min([slice_end, before_offset, list_length])

    end_offset = if first do
      Enum.min([end_offset, start_offset + first])
    else
      end_offset
    end

    start_offset = if last do
      Enum.max([start_offset, end_offset - last])
    else
      start_offset
    end

    from_slice = Enum.max([start_offset - slice_start, 0])
    to_slice = length(records) - (slice_end - end_offset) - 1
    slice = case first do
      0 -> []
      _ -> Enum.slice(records, from_slice..to_slice)
    end

    {edges, _count} = Enum.map_reduce(slice, 0, fn(record, acc) -> {%{ cursor: offset_to_cursor(start_offset+acc), node: record }, acc + 1} end)

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

  def cursor_to_offset(nil, default), do: default
  def cursor_to_offset(cursor, default) do
    case Base.decode64(cursor) do
      {:ok, decoded_cursor} ->
        {int, _} = Integer.parse(String.slice(decoded_cursor, String.length(@prefix)..String.length(decoded_cursor)))
        int
      :error ->
        default
    end
  end

  def cursor_for_object_in_connection(data, object) do
    offset = Enum.find_index(data, fn(obj) -> object == obj end)
    unless offset do
      nil
    else
      offset_to_cursor(offset)
    end
  end

  def offset_to_cursor(offset) do
    Base.encode64("#{@prefix}#{offset}")
  end
end
