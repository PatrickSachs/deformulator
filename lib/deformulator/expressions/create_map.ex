defmodule Deformulator.Expressions.CreateMap do
  defstruct into: nil, values: []

  defmodule Key do
    defstruct key: nil, source: nil

    defimpl String.Chars, for: Deformulator.Expressions.CreateMap.Key do
      def to_string(key) do
        "#{key.key} => #{key.source}"
      end
    end
  end

  # TODO: Handle error label!!
  #     -> label can be {:f, 0}?
  # TODO: Can also be emitted for elements that are not originally in the map, and will thus throw on runtime!
  #     -> Use :maps.merge & detect literal map at optimization phase?
  def parse(ctx, {:put_map_assoc, _error_label, map, target_register, _unknown, {:list, values}}) do
    grouped_values = values |> group_values
    source_map = %Deformulator.Expressions.CreateMap{
      into: map |> Deformulator.Expressions.parse_variable_source(ctx.register),
      values: grouped_values |> Enum.map(fn ({key, source}) ->
        %Deformulator.Expressions.CreateMap.Key{
          key: key |> Deformulator.Expressions.parse_variable_source(ctx.register),
          source: source |> Deformulator.Expressions.parse_variable_source(ctx.register)
        }
      end)
    }
    {reg, var} = Deformulator.Register.create_variable(ctx.register, target_register)
    expr = %Deformulator.Expressions.Bind{
      target: %Deformulator.Expressions.Binding{
        var: var
      },
      source: source_map
    }
    {%Deformulator.Expressions.Context{ctx | register: reg}, expr}
  end

  defp group_values(values, acc \\ [])
  defp group_values([], acc), do: Enum.reverse(acc)
  defp group_values([key, source | next], acc), do: group_values(next, [{key, source} | acc])

  defimpl String.Chars, for: Deformulator.Expressions.CreateMap do
    def to_string(expr) do
      "%{ #{expr.into} | #{expr.values |> Enum.join(", ")} }"
    end
  end
end
