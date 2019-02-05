defmodule FrameTest do
  use ExUnit.Case
  use ExUnitProperties

  property "Frame height = length of input list + 2" do
    check all l <- StreamData.string(:ascii) |> StreamData.list_of(min_length: 1) do
      frame_height = l |> Frame.build() |> length
      length_of_list = length(l)

      assert frame_height == length_of_list + 2
    end
  end

  property "Frame width = length of longest input string + 4" do
    check all l <- StreamData.string(:ascii) |> StreamData.list_of(min_length: 1) do
      frame_width = l |> Frame.build() |> List.first() |> String.length()
      longest_string = Enum.max_by(l, &String.length/1) |> String.length()

      assert frame_width == longest_string + 4
    end
  end

  property "All sides are equal width" do
    check all l <- StreamData.string(:ascii) |> StreamData.list_of(min_length: 1) do
      frame_width = l |> Frame.build() |> List.first() |> String.length()

      assert Enum.all?(Frame.build(l), fn s -> String.length(s) == frame_width end)
    end
  end

  property "Raises error on non-ascii input" do
    check all l <-
                StreamData.string(:printable, min_length: 1)
                |> filter(&(&1 not in 32..255))
                |> StreamData.list_of(min_length: 1) do
      assert_raise ArgumentError, fn -> Frame.build(l) end
    end
  end
end
