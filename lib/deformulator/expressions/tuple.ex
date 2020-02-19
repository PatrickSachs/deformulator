defmodule Deformulator.Expressions.Tuple do
  defstruct elements: []

  defimpl String.Chars, for: Deformulator.Expressions.Tuple do
    def to_string(expr) do
      "{ #{expr.elements |> Enum.join(", ")} }"
    end
  end
end
