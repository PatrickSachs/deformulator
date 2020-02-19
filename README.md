# Deformulator

A prototype for a Beam VM decompiler.

Since I was unable to find a decompiler for the BEAM VM that does more that just extract `debug_info` from the beam files (which are typically not available since they are stripped for non development builds) this is very basic decompiler that attemps to actually decompile the bytecode the Elixir pseduo-code.

## Installation

For now, pull it and run it in IEx.

## Usage

First a .beam file needs to be converted from its binary format into erlang terms. This is a fairly straight forward process.

I've provided a helper function to make this as easy as possible:

```elixir
beam = Deformulator.Loader.load_beam_file!("path/to/beam")
```

Now that the beam file is loaded we can **attempt** to parse it. (Attempt is important, the decompilation tends to fail for all but the most simple modules as there are a lot of cases which I haven't covered yet)

```elixir
parsed = Defmormulator.parse(beam)
```

This will either return a `Deformulator.Module` struct if successful or crash with a message that probably tells you that it can't find a certain register.

This struct implements `String.Chars` to convert it to pseudo-code:

```elixir
parsed |> to_string() |> IO.puts()
```

## Challenges

* The Beam VM is register based, which doesn't map overly nice to decompile it back to a functional language. I've decided to go with an approach that initially assumes that every register is a variable and then tries to optimize these variables away as much as possible without causing side effects.
* The Beam VM has almost no control strctures left in tact (It's essentially goto spaghetti code). To decompile this back into familiar looking statements I am matching on known patterns to transform it back into something similar it started as.
* I've found that the Beam VM isn't too well doucmented. The often referred to ["Beam Book"](https://blog.stenmans.org/theBeamBook/#AP-Instructions) lacks documentation for a lot of instructions, and the ones that are documented are often hard to understand for someone not yet deeply familiar with the VM.

## Example

(Included in the file `./priv/github_demo.erl` for you to play along)

This is our demo Erlang module:

```erlang
-module(github_demo).
-export([hello_world/2]).

hello_world(Name, Age) ->
	FullGreeting = case Age of
		Age when Age >= 18 -> "Access granted, " ++ Name;
		_ -> "Access denied."
	end,
	io:format(FullGreeting).
```

Let's compile it.

```sh
erlc github_demo.erl
```

Now we have the `github_demo.beam` file. Let's launch the Deformulator (`iex -S mix` in the cloned project directory) to decompile the fileagain:

```elixir
iex> {:ok, beam} = Deformulator.Loader.load_beam_file("./priv/github_demo.beam")
#{:ok,
# {:beam_file, :github_demo,
#  [{:hello_world, 2, 2}, {:module_info, 0, 6}, {:module_info, 1, 8}],
#  [vsn: [25922635909147774279658602819796061227]],
#  [
# [...]
```

This is the raw bytecode. Note that no debug info is included in its metadata.

Let's decompile it:

```elixir
iex> decompiled = Deformulator.parse(beam) 
#%Deformulator.Module{
#  functions: [
#    %Deformulator.Function{
#      arity: 2,
# [...]
```

Well this sure is a wall of text! We get an Elixir representation of the beam file, already broken down into the instructions as (the decompiler guessed) they were written in the code file. If someone were to write a tool that would analyze beam files progrmatically, this would be the output they'd use.

But since we are just meatbags, let's convert it to a textual representation:

```elixir
iex> decompiled |> to_string() |> IO.puts()
:ok
# Prints the following to stdout:
defmodule github_demo do
  def hello_world(param0_x0, param1_x1) do
  case erlang.is_ge(param1_x1, 18) do
  true ->
    var2_x1 = param0_x0
    var3_x0 = 'Access granted, '
    var4_x0 = erlang.++(var3_x0, var2_x1)
    io.format(var4_x0)
  false ->
    var5_x0 = 'Access denied.'
    io.format(var5_x0)
end
end
end
```

This looks like a close approximation of what our source code looked like. Noteable differences:

  * It's weird Elixir pseudocode instead of Erlang (It won't compile using Elixir)
  * The case on the Age binding is done differently now
  * The bindings have funky names

The pseducode is currently a replacer. I plan to end up decompiling to Erlang source code (no Elixir since it's nearly impossible to revert macros back into their original state), but for now this serves a proof of concept. 

The binding is caused due to the BEAM essentially only having a single control structure `test`, which tests based on boolean values. There are plans to convert some of these control stuctures back into their original values by mapping on known patterns.

And the binding names are due to the compiled code not retaining the original value names. There are plans to guess variable names based on the functions the call, etc. but for now this is out of scope and the variables are simply named after the register they are stored in.

## Contributing

Since this project is in its infancy and I am far from an expert in the BEAM VM contributions in all forms are appreciated.

Please check the issues section of this GitHub repo or feel free to tackle anything descibed as "planned" in this readme.

A huge help would be a contribution of some unit tests to get started with testing this application. I was strugging to come up with a sensible way to do this that doesn't break whenever you make a miniscule change to the output.
