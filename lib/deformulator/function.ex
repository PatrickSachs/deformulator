defmodule Deformulator.Function do
  @moduledoc """
  This module represents an Erlang function. Use this to interact with a function directly.
  """

  @typedoc """
  Represents a function.

  ## Properties
    * name - The name of the function
    * arity - The arity of the function
    * bytecode - The bytecode split into labels.
    * start_label - The initial label when entering the function
    * register - The variable register
    * expressions - The parsed expressions
    * parameters - TODO
  """

  @type t :: %__MODULE__{
    name: String.t,
    arity: integer,
    bytecode: %{integer => list(any)},
    start_label: integer,
    register: any,
    expressions: list(any),
    parameters: any
  }

  defstruct name: "", arity: 0, bytecode: [], start_label: 0,
    register: %Deformulator.Register{}, expressions: [], parameters: []

  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###
  ### PUBLIC API
  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###

  @doc """
  Parses the bytecode of the given function.

  ## Parameters
    * bytecode - The bytecode in term form.

  ## Returns
    * The generated function

  ## Example
    iex> parse({:function, :encode, 1, 10, [
      {:label, 9}, {:func_info, {:atom, :cow_base64url}, {:atom, :encode}, 1},
      {:label,10}, {:move, {:literal, %{}}, {:x, 1}}, {:call_only, 2, {:cow_base64url, :encode, 2}}
    ]})
    %Deformulator.Function{..}
  """
  def parse(bytecode) do
    {:function, name, arity, start_label, inner_bytecode} = bytecode
    IO.inspect(name, label: "functions")
    {register, param_vars} = insert_argument_register(%Deformulator.Register{}, arity)
    fun = %Deformulator.Function{
      name: name,
      arity: arity,
      start_label: start_label,
      bytecode: preprocess_bytecode(inner_bytecode, %{}, 0),
      register: register,
      parameters: param_vars
    }
    {ctx, expressions} = parse_label!(fun, fun.start_label)
    %Deformulator.Function{fun | register: ctx.register, expressions: expressions}
  end

  @doc """
  Parses the given label ID and returns the list of generated expressions.

  ## Parameters
    * fun - The function.
    * label - The label ID.

  ## Returns
    * {:error, error} for an error.
    * A list of structs representing the expressions. All structs implement
      `String.Chars` and can be converted to an Elixir code string.
      Furthermore the register and function may potentially be updated if new
      variables are declared. Tagged by ok.

  ## Example
      iex> parse_label(%Deformulator.Function{..}, 3)
      {:ok, {%Deformulator.Function{..}, %Deformulator.Register{..}, [%Deformulator.CallMfa{..}, %Deformulator.Literal{..}, ..]}}
  """
  def parse_label(fun, label) do
    if Map.has_key?(fun.bytecode, label) do
      {:ok, Deformulator.Expressions.parse(%Deformulator.Expressions.Context{
        label: label,
        labels: fun.bytecode,
        register: fun.register
      })}
    else
      {:error, :label_not_found}
    end
  end

  def parse_label!(fun, label) do
    case parse_label(fun, label) do
      {:error, :label_not_found} -> raise ArgumentError
      {:ok, result} -> result
    end
  end

  def optimize(fun) do
    fun
    |> optimize_patterns
    |> optimize_variables
  end

  ## Due to every :move being translated into a variable assignment we end up with a large amount of pointless
  ## variable reassignments.
  ## In this step, variables that are only used once are directly inlined.
  defp optimize_variables(fun) do
    fun
  end

  defp optimize_variables_find_declaration(fun, [%Deformulator.Expressions.Bind{
    target: %Deformulator.Expressions.Binding{
      var: target_var
    },
    source: _source
  } | next]) do
    optimize_variables_find_usage(fun, target_var, next)
  end
  defp optimize_variables_find_declaration(fun, [current | next]), do: [current | optimize_variables_find_declaration(fun, next)]
  defp optimize_variables_find_declaration(_fun, []), do: []

  #defp optimize_variables_find_usage(fun, var, [%Deformulator.Expressions.CallMfa{
  #  arguments: arguments
  #}]) do
  #  optimize_variables_find_usage(fun, var, arguments)
  #end
  defp optimize_variables_find_usage(_fun, var, [%Deformulator.Expressions.Bind{
    source: %Deformulator.Expressions.Binding{
      var: var
    },
    target: _target
  }]) do
    :not_impl
  end
  defp optimize_variables_find_usage(fun, var, [expression | next]), do: [expression | optimize_variables_find_usage(fun, var, next)]
  defp optimize_variables_find_usage(_fun, _var, []), do: []


  # Counts how many times variables are assigned to and assigned from.
  defp optimize_variables_count_usages(fun, usage \\ %{}) do
    Enum.reduce(fun.expressions, usage, fn (expression, usage) ->
      :ok
    end)
  end

  defp optimize_patterns(fun) do
    exprs = optimize_patterns(fun, fun.expressions)
    %Deformulator.Function{fun | expressions: exprs}
  end
  # A variable is being assigned to another or a literal to provoke a matchmatch error on failure.
  # e.g. :ok = value
  defp optimize_patterns(fun, [%Deformulator.Expressions.Case{
    expression: %Deformulator.Expressions.CallMfa{
      module: :erlang,
      function: :is_eq_exact,
      arity: 2,
      arguments: arguments
    },
    branches: [
      %Deformulator.Expressions.Case.Branch{
        guard: %Deformulator.Expressions.Literal{value: true},
        expressions: code
      },
      %Deformulator.Expressions.Case.Branch{
        guard: %Deformulator.Expressions.Literal{value: false},
        expressions: [%Deformulator.Expressions.CallMfa{
          module: :erlang,
          function: :exit,
          arguments: [%Deformulator.Expressions.Tuple{
            elements: [
              %Deformulator.Expressions.Literal{value: :badmatch},
              _error_var
            ]
          }]
        }]
      }
    ]
  } | next]) do
    [source, target] = arguments
    [%Deformulator.Expressions.Bind{
      source: source,
      target: target
    } | optimize_patterns(fun, code ++ next)]
  end
  # No last call assignment to x0 register. We always return the last statement
  defp optimize_patterns(_fun, [%Deformulator.Expressions.Bind{
    target: %Deformulator.Expressions.Binding{},
    source: source
  }]) do
    [source]
  end
  # No optimization found, move on.
  defp optimize_patterns(fun, [current | next]), do: [current | optimize_patterns(fun, next)]
  # Done.
  defp optimize_patterns(_fun, []), do: []

  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###
  ### PRIVATE API
  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###

  ## Splits the label instructions into maps for easier access.
  defp preprocess_bytecode([], lookup, _), do: lookup
  defp preprocess_bytecode([{:line, _} | bytecode], lookup, current_label), do: preprocess_bytecode(bytecode, lookup, current_label)
  defp preprocess_bytecode([{:label, label} | bytecode], lookup, _), do: preprocess_bytecode(bytecode, lookup, label)
  defp preprocess_bytecode([exp | bytecode], lookup, current_label) do
    lookup = Map.put(lookup, current_label, Map.get(lookup, current_label, []) ++ [exp])
    preprocess_bytecode(bytecode, lookup, current_label)
  end

  ## Inserts the function arguments into the register and variables.
    # TODO: Also parse pattern matches!
  defp insert_argument_register(reg, arity, current \\ 0)
  defp insert_argument_register(reg, arity, current) when current >= arity, do: {reg, []}
  defp insert_argument_register(reg, arity, current) do
    {reg, var} = Deformulator.Register.create_parameter(reg, current)
    {reg, vars} = insert_argument_register(reg, arity, current + 1)
    {reg, [var | vars]}
  end

  defimpl Deformulator.VariableCounter, for: Deformulator.Function do
    def count(fun) do
      Deformulator.VariableCounter.count(fun.expressions)
        ++ Enum.map(fun.parameters, &({&1, :write}))
    end
  end

  defimpl String.Chars, for: Deformulator.Function do
    def to_string(fun) do
      "def #{fun.name}(#{fun.parameters |> Enum.join(", ")}) do
  #{fun.expressions |> Enum.join("\n  ")}
end"
    end
  end
end
