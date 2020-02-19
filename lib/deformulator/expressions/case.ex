defmodule Deformulator.Expressions.Case do
  defstruct branches: [], expression: nil

  defimpl String.Chars, for: Deformulator.Expressions.Case do
    def to_string(expr) do
      "case #{expr.expression} do\n  #{expr.branches |> Enum.map(&(&1 |> Kernel.to_string |> String.replace("\n", "\n  "))) |> Enum.join("\n  ")}\nend"
    end
  end

  defmodule Branch do
    defstruct expressions: [], guard: nil

    defimpl String.Chars, for: Deformulator.Expressions.Case.Branch do
      def to_string(branch) do
        "#{branch.guard} ->\n  #{branch.expressions |> Enum.join("\n  ")}"
      end
    end
  end
end
