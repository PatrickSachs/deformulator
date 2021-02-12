defprotocol Deformulator.VariableCounter do
  def count(value)
end

defimpl Deformulator.VariableCounter, for: List do
  def count(list) do
    list
    |> Enum.flat_map(&Deformulator.VariableCounter.count/1)
  end
end
