defmodule Deformulator.Expressions.Literal do
  defstruct value: nil

  defimpl String.Chars, for: Deformulator.Expressions.Literal do
    def to_string(exp) do
      Kernel.inspect(exp.value)
    end
  end
end
