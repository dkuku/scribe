defmodule Scribe.Formatter.Index do
  @moduledoc false
  defstruct row: 0, row_max: 0, col: 0, col_max: 0
end

defmodule Scribe.Formatter.Line do
  @moduledoc false
  defstruct data: [], widths: [], style: nil, opts: [], index: nil

  alias Scribe.Formatter.{Index, Line}

  def format(%Line{index: %Index{row: 0}} = line) do
    [top(line), data(line), bottom(line)]
  end

  def format(%Line{} = line) do
    [data(line), bottom(line)]
  end

  def data(%Line{} = line) do
    %Line{
      data: row,
      widths: widths,
      style: style,
      opts: opts,
      index: index
    } = line

    border = style.border_at(index.row, 0, index.row_max, index.col_max)
    left_edge = border.left_edge

    line =
      Enum.reduce((index.col_max - 1)..0, [], fn x, acc ->
        b = style.border_at(index.row, x, index.row_max, index.col_max)
        width = Enum.at(widths, x)
        value = Enum.at(row, x)

        cell_value =
          case opts[:colorize] do
            false -> value |> cell(width)
            _ -> value |> cell(width) |> colorize(style.color(value))
          end

        [cell_value, b.right_edge | acc]
      end)

    [left_edge, line, "\n"]
  end

  def cell(x, width) do
    len = min(String.length(inspect(x)) + 2, width)
    [truncate([" ", inspect(x), padding(width - len)], width - 2), " "]
  end

  def cell_value(x, padding, max_width) when padding >= 0 do
    truncate([" ", inspect(x), padding(padding)], max_width)
  end

  defp truncate(elem, width) do
    elem
    |> IO.iodata_to_binary()
    |> String.slice(0..width)
  end

  def colorize(string, color) do
    [color, string, IO.ANSI.reset()]
  end

  def top(%Line{widths: widths, style: style, index: index, opts: opts}) do
    border = style.border_at(index.row, 0, index.row_max, index.col_max)
    top_left = border.top_left_corner

    line =
      Enum.reduce((index.col_max - 1)..0, [], fn x, acc ->
        b = style.border_at(index.row, x, index.row_max, index.col_max)
        width = Enum.at(widths, x)

        duplicate(b.top_edge, width - 1) ++ [b.top_right_corner | acc]
      end)

    color_prefix =
      if Keyword.get(opts, :colorize, true) do
        style.default_color()
      else
        ""
      end

    [color_prefix, top_left, add_newline(line)]
  end

  def bottom(%Line{widths: widths, style: style, index: index}) do
    border = style.border_at(index.row, 0, index.row_max, index.col_max)
    bottom_left = border.bottom_left_corner

    line =
      Enum.reduce((index.col_max - 1)..0, [], fn x, acc ->
        b = style.border_at(index.row, x, index.row_max, index.col_max)
        width = Enum.at(widths, x)

        duplicate(b.bottom_edge, width - 1) ++ [b.bottom_right_corner | acc]
      end)

    [bottom_left, add_newline(line)]
  end

  def add_newline(line) do
    if Enum.all?(line, &(&1 == "")) do
      []
    else
      [line, "\n"]
    end
  end

  defp padding(amount) do
    duplicate(" ", amount)
  end

  defp duplicate(char, amount) do
    Enum.map(0..amount, fn _x -> char end)
  end
end
