defmodule Deformulator do

  def parse(bytecode) do
    bytecode
    |> Deformulator.Module.parse
    |> Deformulator.Module.optimize
  end
end
