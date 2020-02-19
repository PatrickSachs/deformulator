defmodule Deformulator.Expressions.Bind do
  defstruct target: nil, source: nil

  defimpl String.Chars, for: Deformulator.Expressions.Bind do
    def to_string(exp) do
      #IO.inspect(exp, label: :bind)
      "#{exp.target} = #{exp.source}"
    end
  end
end
