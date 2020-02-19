defmodule ModuleTest do
  use ExUnit.Case
  doctest Deformulator

  @tag :skip
  test "Decompile cow_base64url" do
    beam = File.read!("./priv/test/cow_base64url.beam.asm")
    bytecode = Deformulator.Loader.erl_string_to_term(beam)
    mod = Deformulator.Module.parse(bytecode)
    assert mod |> to_string() === ""
  end
end
