defmodule Scribe do
  @moduledoc """
  Pretty-print tables of structs, maps and lists
  """

  @type data ::
          []
          | [...]
          | term

  @typedoc ~S"""
  Options for configuring table output.

  - `:colorize` - When `false`, disables colored output. Defaults to `true`
  - `:inspect` - When `false`, uses puts for display data, otherwise inspect`
  - `:data` - Defines table headers
  - `:device` - Where to print (defaults to STDOUT)
  - `:style` - Style callback module. Defaults to `Scribe.Style.Default`
  - `:width` - Defines table width. Defaults to `:infinite`
  """
  @type format_opts :: [
          colorize: boolean,
          inspect: boolean,
          data: [...],
          style: module,
          width: integer
        ]

  @doc false
  def compile_auto_inspect? do
    Application.get_env(:scribe, :compile_auto_inspect, false)
  end

  @doc ~S"""
  Prints a table from given data.

  ## Examples

      iex> Scribe.print([])
      :ok

      iex> Scribe.print([%{key: :value, test: 1234}], colorize: false)
      :ok
  """
  @spec print(data, format_opts) :: :ok
  def print(_results, opts \\ [])

  def print([], _opts), do: :ok

  def print(results, opts) do
    dev = opts |> Keyword.get(:device, :stdio)
    results = results |> format(opts)
    dev |> IO.puts(results)
  end

  def console(results, opts \\ []) do
    results
    |> format(opts)
    |> Pane.console()
  end

  @doc ~S"""
  Formats data into a printable table string.

  ## Examples

      iex> Scribe.format([])
      :ok

      iex> Scribe.format(%{test: 1234}, colorize: false)
      "+-------+\n| :test |\n+-------+\n| 1234  |\n+-------+\n"
  """
  @spec format([] | [...] | term) :: String.t() | :ok
  def format(_results, opts \\ [])
  def format([], _opts), do: :ok

  def format(results, opts) when is_map(results) do
    case Table.Reader.init(results) do
      {:columns, _, _} ->
        results |> Table.to_rows() |> Enum.to_list() |> format(opts)

      :none ->
        format([results], opts)
    end
  end

  def format(results, opts) do
    keys = fetch_keys(results, opts[:data])

    headers = map_string_values(keys)
    data = Enum.map(results, &map_string_values(&1, keys))

    table = [headers | data]
    Scribe.Table.format(table, Enum.count(table), Enum.count(keys), opts)
  end

  defp map_string_values(keys), do: Enum.map(keys, &string_value(&1))
  defp map_string_values(row, keys), do: Enum.map(keys, &string_value(row, &1))

  defp string_value(%{name: name, key: _key}), do: name

  defp string_value(map, %{name: _name, key: key}) when is_function(key),
    do: key.(map)

  defp string_value(map, %{name: _name, key: key}) when is_map(map),
    do: Map.get(map, key)

  defp string_value(list, %{name: _name, key: key}) when is_list(list),
    do: Keyword.get(list, key)

  defp fetch_keys([first | _rest], nil), do: fetch_keys(first)
  defp fetch_keys(_list, opts), do: process_headers(opts)

  defp fetch_keys(list) when is_list(list),
    do: list |> Keyword.keys() |> process_headers()

  defp fetch_keys(map) when is_map(map),
    do: map |> Map.keys() |> process_headers()

  defp process_headers(opts) do
    for opt <- opts do
      case opt do
        {name, key} -> %{name: name, key: key}
        :__struct__ -> %{name: STRUCT, key: :__struct__}
        key -> %{name: key, key: key}
      end
    end
  end
end
