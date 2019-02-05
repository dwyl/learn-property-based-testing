# Learn Property Based Testing (with Elixir)

## Why?

We all (hopefully) test our applications, but are you really testing them, or are you just testing the "happy path"?

Traditional unit tests are "Example Based". We call our function a number of times, passing it an example of an expected input each time, and make sure it does what we expect it to.

But what happens if your function receives an _unexpected_ input?

You can't write an example based test for an example you haven't thought of. That's where property based testing comes in. Instead of testing examples, you define and test the properties of your code.

For example, if you were writing some code to validate a credit card number, one of the properties would be that it would only accept numbers as an input. Then, a property based test would validate that any other input returned an error.

## What?

Property Based Testing originated with [QuickCheck](https://en.wikipedia.org/wiki/QuickCheck), a Haskell library created in 1999. QuickCheck takes assertions about about logical properties that a program should fulfill, then generates test cases that try to fail these assertions.

Many Property Based Testing libraries have been created since then, and the one we're going to be using is [StreamData](https://hexdocs.pm/stream_data/StreamData.html), which, at the time of writing is scheduled to be included in a future release of Elixir core.

## How?

Imagine you've been tasked with writing a progam that accepts a list of strings, and must print those strings inside a frame of asterisks:

```elixir
["Hello", "World"]

*********
* Hello *
* World *
*********

["Hi"]

******
* Hi *
******

["Property", "Based", "Testing", "Is", "Great"]

************
* Property *
* Based    *
* Testing  *
* Is       *
* Great    *
************
```

Now, to write some tests for this, we need to know, what are the properties of this program?

- The outputted frame should have a height that is the length of the list of strings, plus two for the top and bottom line of asterisks.
- The frame should have a width that is the length of the longest string, plus four for the two spaces and two asterisks on either side of the word.
- Each line of the frame should be of equal width.

There are a few other properties we could add for completeness, such as what should happen if a non-string is passed, but we'll stick with these logical ones for now.

So now we translate those properties into code. As mentioned above, we'll be using the StreamData library to generate test cases.

The first thing we need to do is set up our test suite. Create a new elixir project using `mix new frame`, then put the following in your `test/frame_test.exs` file:

``` elixir
defmodule FrameTest do
  use ExUnit.Case
  use ExUnitProperties
end
```

We need to `use ExUnit.Case` to access our usual `assert` methods, and we also `use ExUnitProperties` which is [part of the StreamData library](https://hexdocs.pm/stream_data/ExUnitProperties.html#content), and will give us access to generators and property check methods.

``` elixir
property "height = length of list + 2" do
    check all l <- string(:printable) |> list_of(min_length: 1) do
      frame_height = l |> Frame.build() |> length
      length_of_list = length(l)

      assert frame_height == length_of_list + 2
    end
  end
```

`property` is part of `ExUnitProperties` that is used where we would usually use `test`. It defines a property test, and imports functions from `StreamData`.

`check` is a macro that runs our tests. Between `check all` and `do`, we define our generators, which generate the input for our tests. Here we're using [`StreamData.string`](https://hexdocs.pm/stream_data/StreamData.html#string/2) and [`StreamData.list_of`](https://hexdocs.pm/stream_data/StreamData.html#list_of/2) to create a random length list of random length strings. Because these functions are imported within `property`, we don't need to prefix them with the `StreamData` module name.

We're passing options to our generators here. We pass `:printable` to string, this means our generator will create strings using all printable unicode characters. We also pass `min_length: 1` to `list_of` to ensure we aren't given an empty list. See [the docs](https://hexdocs.pm/stream_data/StreamData.html#content) for a full list of options for all generators.

Then, inside the body (between `do` and `end`) we make our assertions. These assertions should be as simple as possible. If your properties are too complex, you would need to write tests to validate those, and those tests would need to be validated, and so on... Limiting our assertions to be as simple as possible means we can look at them and instantly be sure they are correct.

Now we'll define our other properties

``` elixir
property "Frame width = length of longest input string + 4" do
    check all l <- string(:printable) |> list_of(min_length: 1) do
      frame_width = l |> Frame.build() |> List.first() |> String.length()
      longest_string = Enum.max_by(l, &String.length/1) |> String.length()

      assert frame_width == longest_string + 4
    end
  end

property "All sides are equal width" do
    check all l <- string(:printable) |> list_of(min_length: 1) do
      frame_width = l |> Frame.build() |> List.first() |> String.length()

      assert Enum.all?(Frame.build(l), fn s -> String.length(s) == frame_width end)
    end
  end
```

As you can see, we're using the same generator for all of these properties, so we can factor that out into a function:

``` elixir
defp list_string() do
  string(:printable) |> list_of(min_length: 1)
end

property "height = length of list + 2" do
  check all l <- list_string() do
    ...
  end
end

property "Frame width = length of longest input string + 4" do
  check all l <- list_string() do
    ...
  end
end

property "All sides are equal width" do
  check all l <- list_string() do
    ...
  end
end
```

Now that we have our properties defined, let's write some code to test.

``` elixir
defmodule Frame do
  def build(input) do
    longest = Enum.max_by(input, fn s -> String.length(s) end) |> String.length()

    top = String.duplicate("*", longest + 4)

    input
    |> Enum.map(fn s ->
      "* " <> s <> suffix(longest - String.length(s) + 1)
    end)
    |> List.insert_at(0, top)
    |> List.insert_at(-1, top)
  end

  defp suffix(len) do
    String.duplicate(" ", len) <> "*"
  end
end
```

I don't want to spend too much time on this, but here we're taking the list of strings, mapping over it to make each string start with "* ", of equal length, and ending with "*". We then add a line of stars to the start and end of the list.

Now that we have the code and the tests, let's run them. First, make sure you've added `StreamData` to your `mix.exs`

```
defp deps do
  [
    {:stream_data, "~> 0.4.2", only: :test}
  ]
end
```

Then run our tests:

```
$ mix test

Finished in 1.7 seconds
3 properties, 1 failure
```

And we get one failure. This is good, it means at least one of our tests was useful. If we take a look at the output, we can try to figure out what went wrong.

```
1) property All sides are equal width (FrameTest)
     test/frame_test.exs:23
     Failed with generated values (after 45 successful runs):

         * Clause:    l <- string_list()
           Generated: ["𑠭򆚃񼉽𘖋񣣪󡼷怒󬈔񎩞򯐴򪇞󾠢򤻑󋞸󰅰񴅀눗󼇄񩈦񮝧򶑬𼟨ꖌ򒏮򃡒"]

     Expected truthy, got false
```

We can see that the test generated some Chinese characters, as well as some unicode characters that can't display on my machine. The problem is that some unicode characters display over two spaces, but only count as one character. This throws off our string length, as even though it looks correct, the number of characters is too few.

There's not much we can do about characters that take too many spaces, but we can ensure our code handles them.

``` elixir
property "Raises error on non-ascii input" do
  check all l <-
            string(:printable, min_length: 1)
            |> filter(&(&1 not in 32..255))
            |> list_of(min_length: 1) do
    assert_raise ArgumentError, fn -> Frame.build(l) end
  end
end
```

Here we create a property that asserts that an error is raised for all non-ascii characters.

We then add this condition to our code.

``` elixir
def build(input) do
  ...

  input
  |> validate()
  |> Enum.map(fn s ->
  ...
end

defp validate(input) do
  case Enum.all?(input, &is_ascii?/1) do
    true -> input
    false -> raise ArgumentError
  end
end

defp is_ascii?(str) do
  str |> String.to_charlist() |> List.ascii_printable?()
end
```

Here we check that each character in the input is `ascii_printable`, and if not raises an `ArgumentError`.

We now also need to remember to update our generator. We no longer want to create a list of `:printable` strings, but a list of `:ascii` strings.

``` elixir
defp list_string() do
  string(:ascii) |> list_of(min_length: 1)
end
```

Now, when we run our tests, we should see them all pass.

```
Finished in 1.4 seconds
4 properties, 0 failures
```

By default, `check` generates 100 inputs to run tests. If you want to increase/decrease this, you can pass `max_runs` as an option:

``` elixir
property "max run test property"  do
  check all l <- StreamData.string(), max_runs: 1000 do
    ...
  end
end
```

The more tests you run, the more confidence you can have in your code. You can even set this to an incredibly high number when you first run your tests, then set it back to normal when running them regularly on your CI.

## Read More

### Articles
* https://elixir-lang.org/blog/2017/10/31/stream-data-property-based-testing-and-data-generation-for-elixir/
* https://jeffkreeftmeijer.com/mix-proper/
* http://whatdidilearn.info/2018/04/22/property-based-testing.html

### Books
* https://pragprog.com/book/fhproper/property-based-testing-with-proper-erlang-and-elixir

### Videos
* https://youtu.be/x2ckfhqB9nA?t=1964 - Keynote - José Valim - ElixirConf EU 2018
* https://www.youtube.com/watch?v=p84DMv8TQuo - Property-based Testing is a Mindset - Andrea Leopardi - ElixirConf EU 2018
* ElixirConf 2018 - Picking Properties to Test in Property Based Testing - Michael Stalker https://www.youtube.com/watch?v=OVLTHGaTi7k
* ElixirConf 2018 - Sustainable Testing - Andrew Bennett - https://www.youtube.com/watch?v=9XRe1ce5eak
