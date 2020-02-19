defmodule Deformulator.Expressions.Binding do
  defstruct var: ""

  defprotocol Usage do
    @doc """
    Counts how many times an expression used certain variables.
    """
    def count_variables(exp, usage)
  end

  defimpl Usage, for: Deformulator.Expressions.Binding do
    def count_variables(exp, usage) do
      Map.update(usage, exp.var, 1, &(&1 + 1))
    end
  end

  defimpl String.Chars, for: Deformulator.Expressions.Binding do
    def to_string(exp) do
      exp.var
    end
  end
end
