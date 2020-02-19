defmodule Deformulator.Expressions.CallMfa do
  defstruct module: nil, function: nil, arity: 0, arguments: []

  defimpl String.Chars, for: Deformulator.Expressions.CallMfa do
    def to_string(exp) do
      "#{exp.module}.#{exp.function}(#{exp.arguments |> Enum.join(", ")})"
    end
  end
end
