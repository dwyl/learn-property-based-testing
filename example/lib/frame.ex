defmodule Frame do
  @moduledoc """
    Displays a list of strings
    within a 'frame' of asterisks
  """
  def run(input) do
    input
    |> build()
    |> print()
  end

  def build(input) do
    longest = Enum.max_by(input, &String.length/1) |> String.length()

    top = String.duplicate("*", longest + 4)

    input
    |> validate()
    |> Enum.map(fn s ->
      "* " <> s <> suffix(longest - String.length(s) + 1)
    end)
    |> List.insert_at(0, top)
    |> List.insert_at(-1, top)
  end

  defp validate(input) do
    case Enum.all?(input, &is_ascii?/1) do
      true -> input
      false -> raise ArgumentError
    end
  end

  defp print(frame) do
    frame
    |> Enum.join("\n")
    |> IO.puts()
  end

  defp suffix(len) do
    String.duplicate(" ", len) <> "*"
  end

  defp is_ascii?(str) do
    str |> String.to_charlist() |> List.ascii_printable?()
  end
end
