defmodule Deformulator.Expressions.Bind do
  defstruct target: nil, source: nil

  defimpl String.Chars, for: Deformulator.Expressions.Bind do
    def to_string(exp) do
      #IO.inspect(exp, label: :bind)
      "#{exp.target} = #{exp.source}"
    end
  end

  defimpl Deformulator.VariableCounter, for: Deformulator.Expressions.Bind do
    def count(bind) do
      source_var = case bind.source do
        %Deformulator.Expressions.Binding{var: var} -> {var, :read}
        _ -> Deformulator.VariableCounter.count(bind.source)
      end
      target_var = case bind.target do
        %Deformulator.Expressions.Binding{var: var} -> {var, :bind}
        _ -> Deformulator.VariableCounter.count(bind.target)
      end
      List.flatten([source_var, target_var])
    end
  end
end
