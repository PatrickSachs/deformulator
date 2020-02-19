defmodule Deformulator.Expressions.Unknown do
  defstruct raw: nil

  defimpl String.Chars, for: Deformulator.Expressions.Unknown do
    def to_string(ukn) do
      "#unknown<#{inspect(ukn.raw)}>"
    end
  end
end
