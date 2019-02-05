# Learn Property Based Testing (with Elixir)

## Why?

We all (hopefully) test our applications, but are you really testing them, or are you just testing the "happy path"?

Traditional unit tests are "Example Based". We call our function a number of times, passing it an example of an expected input each time, and make sure it does what we expect it to.

But what happens if your function receives an _unexpected_ input?

You can't write an example based test for an example you haven't thought of. That's where property based testing comes in. Instead of testing examples, you define and test the properties of your code.

For example, if you were writing some code to validate a credit card number, one of the properties would be that it would only accept numbers as an input. Then, a property based test would validate that any other input returned an error.

## What?

Property Based Testing originated with QuickCheck, a Haskell library created in 1999. QuickCheck takes assertions about about logical properties that a program should fulfill, then generates test cases that try to fail these assertions.

Many Property Based Testing libraries have been created since then, and the one we're going to be using is StreamData, which, at the time of writing is scheduled to be included in a future release of Elixir core.
