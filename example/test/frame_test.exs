defmodule FrameTest do
  use ExUnit.Case
  doctest Frame

  test "greets the world" do
    assert Frame.hello() == :world
  end
end
