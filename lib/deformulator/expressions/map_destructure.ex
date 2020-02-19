defmodule Deformulator.Expressions.MapDestructure do
  defstruct keys: [], map: nil

  defmodule Key do
    defstruct key: nil, into: nil

    defimpl String.Chars, for: Deformulator.Expressions.MapDestructure.Key do
      def to_string(key) do
        "#{key.key} = #{key.into}"
      end
    end
  end

  # TODO: Handle error label!!
  #     -> label can be {:f, 0}?
  def parse(ctx, {:get_map_elements, _error_label, register, {:list, values}}) do
    grouped = values |> group_values()
    {reg, keys} = Enum.reduce(grouped, {ctx.register, []}, fn ({key, into}, {reg, keys}) ->
      {reg, var} = Deformulator.Register.create_variable(reg, into)
      {reg, [%Deformulator.Expressions.MapDestructure.Key{
        key: key |> Deformulator.Expressions.parse_variable_source(reg),
        into: %Deformulator.Expressions.Binding{
          var: var
        }
      } | keys]}
    end)
    expr = %Deformulator.Expressions.MapDestructure{
      map: register |> Deformulator.Expressions.parse_variable_source(reg),
      keys: keys
    }
    {%Deformulator.Expressions.Context{ctx | register: reg}, expr}
  end

  defp group_values(values, acc \\ [])
  defp group_values([], acc), do: Enum.reverse(acc)
  defp group_values([key, target | next], acc), do: group_values(next, [{key, target} | acc])

  defimpl String.Chars, for: Deformulator.Expressions.MapDestructure do
    def to_string(exp) do
      "%{ #{exp.keys |> Enum.join(", ")} } = #{exp.map}"
    end
  end
end
