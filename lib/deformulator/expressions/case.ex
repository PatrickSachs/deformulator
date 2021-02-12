defmodule Deformulator.Expressions.Case do
  defstruct branches: [], expression: nil

  defimpl String.Chars, for: Deformulator.Expressions.Case do
    def to_string(expr) do
      "case #{expr.expression} do\n  #{expr.branches |> Enum.map(&(&1 |> Kernel.to_string |> String.replace("\n", "\n  "))) |> Enum.join("\n  ")}\nend"
    end
  end

  defimpl Deformulator.VariableCounter, for: Deformulator.Expressions.Case do
    def count(expr) do
      #require IEx
      #IEx.pry
      expr_vars = Deformulator.VariableCounter.count(expr.expression)
      branch_vars = Enum.map(expr.branches, &Deformulator.VariableCounter.count/1)
      List.flatten(branch_vars, expr_vars)
    end
  end

  defmodule Branch do
    defstruct expressions: [], guard: nil

    defimpl Deformulator.VariableCounter, for: Deformulator.Expressions.Case.Branch do
      def count(branch) do
        Deformulator.VariableCounter.count(branch.expressions)
          ++ Deformulator.VariableCounter.count(branch.guard)
      end
    end

    defimpl String.Chars, for: Deformulator.Expressions.Case.Branch do
      def to_string(branch) do
        "#{branch.guard} ->\n  #{branch.expressions |> Enum.join("\n  ")}"
      end
    end
  end
end
