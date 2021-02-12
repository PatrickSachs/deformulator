defmodule Deformulator.Expressions.CallMfa do
  defstruct module: nil, function: nil, arity: 0, arguments: []

  defimpl String.Chars, for: Deformulator.Expressions.CallMfa do
    def to_string(exp) do
      "#{exp.module}.#{exp.function}(#{exp.arguments |> Enum.join(", ")})"
    end
  end

  defimpl Deformulator.VariableCounter, for: Deformulator.Expressions.CallMfa do
    def count(mfa) do
      mfa.arguments
      |> Enum.map(&count_argument/1)
      |> List.flatten()
    end

    defp count_argument(%Deformulator.Expressions.Binding{var: var}) do
      {var, :read}
    end
    defp count_argument(arg) do
      Deformulator.VariableCounter.count(arg)
    end
  end
end
