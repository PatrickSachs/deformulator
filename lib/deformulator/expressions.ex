defmodule Deformulator.Expressions do
  defmodule Context do
    @moduledoc """
    A parser context.
    """

    @typedoc """
    Represents parser context.

    ## Properties
      * function - The function we are in. nil if outside a function context.
      * label - The label currently being parsed. Typically only valid if we also have a function.
    """
    @type t :: %__MODULE__{
      register: any,
      label: integer,
      labels: %{}
    }

    defstruct register: %Deformulator.Register{}, label: 0, labels: %{}
  end

  @doc """
  Parses the bytecode of a list of expressions.

  ## Parameters

    * reg - The register we are using.
    * exps - The list of expressions
    * acc - The list of accumulated expressions.

  ## Returns

    The parsed expression structs.
  """
  def parse(ctx), do: parse(ctx, Map.get(ctx.labels, ctx.label))
  def parse(ctx, values, acc \\ [])
  def parse(%Context{labels: labels, label: label} = ctx, [], acc) do
    # If we are done with the current label and it was not returned explictly we "bleed" into the next label.
    next_label_num = label + 1
    case Map.get(labels, next_label_num) do
      nil -> finalize_parsing(ctx, acc)
      next_label -> parse(%Context{ctx | label: next_label_num}, next_label, acc)
    end
  end
  # Memory allocations are dropped since we don't explictly do that in code.
  def parse(ctx, [{:allocate, _, _} | next], acc), do: parse(ctx, next, acc)
  # Literals and just insterted 1:1.
  def parse(ctx, [{:move, {:literal, literal}, target} | next], acc) do
    # Variables
    {reg, var_target} = Deformulator.Register.create_variable(ctx.register, target)
    # Assembly expression
    exp = %Deformulator.Expressions.Bind{
      target: %Deformulator.Expressions.Binding{
        var: var_target
      },
      source: %Deformulator.Expressions.Literal{
        value: literal
      }
    }
    parse(%Context{ctx | register: reg}, next, [exp | acc])
  end
  # Register moves are translated to variable reassignments. In practice this is not
  # related at all, but this will allow us to normalize the data structure later.
  def parse(ctx, [{:move, source, target} | next], acc) do
    # Variables
    var_source = parse_variable_source(source, ctx.register)
    {reg, var_target} = Deformulator.Register.create_variable(ctx.register, target)
    # Assembly expression
    exp = %Deformulator.Expressions.Bind{
      target: %Deformulator.Expressions.Binding{
        var: var_target
      },
      source: var_source
    }
    parse(%Context{ctx | register: reg}, next, [exp | acc])
  end
  # External calls
  def parse(ctx, [{:call_ext, arity, {:extfunc, module, function, _arity}} | next], acc) do
    call_expr = %Deformulator.Expressions.CallMfa{
      module: module,
      function: function,
      arity: arity,
      arguments: parse_fn_args(arity, ctx.register)
    }
    {reg, bind_var} = Deformulator.Register.create_variable(ctx.register, {:x, 0})
    expr = %Deformulator.Expressions.Bind{
      target: %Deformulator.Expressions.Binding{
        var: bind_var
      },
      source: call_expr
    }
    parse(%Context{ctx | register: reg}, next, [expr | acc])
  end
  # Internal calls
  def parse(ctx, [{:call, arity, {module, function, _arity}} | next], acc) do
    call_expr = %Deformulator.Expressions.CallMfa{
      module: module,
      function: function,
      arity: arity,
      arguments: parse_fn_args(arity, ctx.register)
    }
    {reg, bind_var} = Deformulator.Register.create_variable(ctx.register, {:x, 0})
    expr = %Deformulator.Expressions.Bind{
      target: %Deformulator.Expressions.Binding{
        var: bind_var
      },
      source: call_expr
    }
    parse(%Context{ctx | register: reg}, next, [expr | acc])
  end
  # Call without CP update
  def parse(ctx, [{:call_ext_only, arity, {:extfunc, module, function, _arity}} | next], acc) do
    expr = %Deformulator.Expressions.CallMfa{
      module: module,
      function: function,
      arity: arity,
      arguments: parse_fn_args(arity, ctx.register)
    }
    parse(ctx, next, [expr | acc])
  end
  # External Call without CP update
  def parse(ctx, [{:call_only, arity, {module, function, _arity}} | next], acc) do
    expr = %Deformulator.Expressions.CallMfa{
      module: module,
      function: function,
      arity: arity,
      arguments: parse_fn_args(arity, ctx.register)
    }
    parse(ctx, next, [expr | acc])
  end
  # Tail calls internal
  def parse(ctx, [{:call_last, arity, {module, function, _arity}, _deallocate} | next], acc) do
    expr = %Deformulator.Expressions.CallMfa{
      module: module,
      function: function,
      arity: arity,
      arguments: parse_fn_args(arity, ctx.register)
    }
    parse(ctx, next, [expr | acc])
  end
  # Tail calls external
  def parse(ctx, [{:call_ext_last, arity, {:extfunc, module, function, _arity}, _deallocate} | next], acc) do
    expr = %Deformulator.Expressions.CallMfa{
      module: module,
      function: function,
      arity: arity,
      arguments: parse_fn_args(arity, ctx.register)
    }
    parse(ctx, next, [expr | acc])
  end
  # A native function call
  # {:gc_bif, :bit_size, {:f, 0}, 2, [x: 0], {:x, 2}},
  def parse(ctx, [{:gc_bif, function, _unknown, _preserve_registers, arguments, result_register} | next], acc) do
    call_expr = %Deformulator.Expressions.CallMfa{
      module: :erlang,
      function: function,
      arity: length(arguments),
      arguments: arguments |> Enum.map(&(&1 |> parse_variable_source(ctx.register)))
    }
    {reg, bind_var} = Deformulator.Register.create_variable(ctx.register, result_register)
    expr = %Deformulator.Expressions.Bind{
      source: call_expr,
      target: %Deformulator.Expressions.Binding{
        var: bind_var
      }
    }
    parse(%Context{ctx | register: reg}, next, [expr | acc])
  end
  # Badmatch exit
  def parse(ctx, [{:badmatch, register} | _], acc) do
    call_expr = %Deformulator.Expressions.CallMfa{
      module: :erlang,
      function: :exit,
      arity: 1,
      arguments: [%Deformulator.Expressions.Tuple{
        elements: [
          %Deformulator.Expressions.Literal{ value: :badmatch },
          %Deformulator.Expressions.Binding{ var: Deformulator.Register.find_variable!(ctx.register, register) }
        ]
      }]
    }
    finalize_parsing(ctx, [call_expr | acc])
  end
  # Test to check data type
  def parse(ctx, [{:test, function, {:f, label}, arguments} | next], acc) do
    #require IEx
    #IEx.pry
    # TODO: Test due to context changes!!!
    {true_ctx, true_exprs} = parse(ctx, next)
    {false_ctx, false_exprs} = parse(%Context{true_ctx | label: label})
    #require IEx
    #IEx.pry

    case_expr = %Deformulator.Expressions.Case{
      expression: %Deformulator.Expressions.CallMfa{
        module: :erlang,
        function: function,
        arity: length(arguments),
        arguments: arguments |> Enum.map(&(&1 |> parse_variable_source(ctx.register)))
      },
      branches: [
        %Deformulator.Expressions.Case.Branch{
          guard: %Deformulator.Expressions.Literal{ value: true },
          expressions: true_exprs
        },
        %Deformulator.Expressions.Case.Branch{
          guard: %Deformulator.Expressions.Literal{ value: false },
          expressions: false_exprs
        }
      ]
    }
    finalize_parsing(false_ctx, [case_expr | acc])
  end
  # Jump to label (Should always be last instruction in a label?)
  def parse(ctx, [{:jump, {:f, label}}], acc) do
    {ctx, exprs} = parse(%Context{ctx | label: label})
    # TODO: Not a fan of the reversing in general
    finalize_parsing(ctx, Enum.reverse(exprs) ++ acc)
  end
  # Insert into map
  def parse(ctx, [{:put_map_assoc, _error_label, _map, _target_regster, _unknown, _values} = put_map_assoc | next], acc) do
    {ctx, expr} = Deformulator.Expressions.CreateMap.parse(ctx, put_map_assoc)
    parse(ctx, next, [expr | acc])
  end
  # Extract from map
  def parse(ctx, [{:get_map_elements, _error_label, _map, _values} = get_map_elements | next], acc) do
    {ctx, expr} = Deformulator.Expressions.MapDestructure.parse(ctx, get_map_elements)
    parse(ctx, next, [expr | acc])
  end
  def parse(ctx, [:return | _], acc) do
    finalize_parsing(ctx, acc)
  end
  def parse(ctx, [unknown | next], acc) do
    expr = %Deformulator.Expressions.Unknown{
      raw: unknown
    }
    parse(ctx, next, [expr | acc])
  end

  @doc """
  Parses a value that can potentially stand in as a variable. This can include literals or an actual binding.

  ## Paramters

    * source - The source. (e.g. `{:atom, :hello_world}`)
    * fun - The function we are in.
    * reg - The register to use for variable lookups.

  ## Returns

    * The expression to get the value

  ## Example

      iex> parse_variable_source({:atom, :hello_world}, %Deformulator.Function{..}, %Deformulator.Register{..})
      %Deformulator.Expressions.Literal{..}
      iex> parse_variable_source({:x, 1}, %Deformulator.Function{..}, %Deformulator.Register{..})
      %Deformulator.Expressions.Binding{..}
  """
  def parse_variable_source({:literal, literal}, _reg), do: %Deformulator.Expressions.Literal{ value: literal }
  def parse_variable_source({:integer, integer}, _reg), do: %Deformulator.Expressions.Literal{ value: integer }
  def parse_variable_source({:atom, atom}, _reg), do: %Deformulator.Expressions.Literal{ value: atom }
  def parse_variable_source(register, reg), do: %Deformulator.Expressions.Binding{ var: Deformulator.Register.find_variable!(reg, register) }

  defp finalize_parsing(ctx, exprs), do: {ctx, Enum.reverse(exprs)}

  defp parse_fn_args(0, _reg), do: []
  defp parse_fn_args(n, reg) do
    var_name = Deformulator.Register.find_variable!(reg, {:x, n - 1})
    parse_fn_args(n - 1, reg) ++ [%Deformulator.Expressions.Binding{
      var: var_name
    }]
  end
end
