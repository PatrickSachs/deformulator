defmodule FunctionTest do
  use ExUnit.Case
  doctest Deformulator

  def bytecode1 do
    {:function, :encode, 2, 12, [
        {:line, 10},
      {:label, 11},
        {:func_info, {:atom, :cow_base64url}, {:atom, :encode}, 2},
      {:label, 12},
        {:allocate, 1, 2},
        {:move, {:x, 1}, {:y, 0}},
        {:call_ext, 1, {:extfunc, :base64, :encode, 1}},
        {:move, {:literal, <<>>}, {:x, 2}},
        {:move, {:y, 0}, {:x, 1}},
        {:call_last, 3, {:cow_base64url, :encode, 3}, 1}
    ]}
  end

  test "simple decompile 1" do
    code = "def encode(param0_x0, param1_x1) do
  var2_y0 = param1_x1
  var3_x0 = base64.encode(param0_x0)
  var4_x2 = \"\"
  var5_x1 = var2_y0
  cow_base64url.encode(var3_x0, var5_x1, var4_x2)
end"
    assert bytecode1 |> Deformulator.Function.parse |> to_string == code
  end

  test "simple decompile and optimization 1" do
    code = "def encode(param0_x0, param1_x1) do
  cow_base64url.encode(base64.encode(param0_x0), param1_x1, \"\")
end"
    assert bytecode1 |> Deformulator.Function.parse |> Deformulator.Function.optimize |> to_string == code
  end

  def bytecode2 do
    {:function, :encode, 1, 10, [
        {:line, 9},
      {:label, 9},
        {:func_info, {:atom, :cow_base64url}, {:atom, :encode}, 1},
      {:label,10},
        {:move, {:literal, %{}}, {:x, 1}},
        {:call_only, 2, {:cow_base64url, :encode, 2}}
    ]}
  end

  test "simple decompile 2" do
    code = "def encode(param0_x0) do
  var1_x1 = %{}
  cow_base64url.encode(param0_x0, var1_x1)
end"
    assert bytecode2 |> Deformulator.Function.parse |> to_string == code
  end

  test "simple decompile and optimization 2" do
    code = "def encode(param0_x0) do
  cow_base64url.encode(param0_x0, %{})
end"
    assert bytecode2 |> Deformulator.Function.parse |> Deformulator.Function.optimize |> to_string == code
  end

  @tag :skip
  test "complex decompile 1" do
    bytecode = {:function, :decode, 2, 4, [
        {:line, 2},
      {:label, 3},
        {:func_info, {:atom, :cow_base64url}, {:atom, :decode}, 2},
      {:label, 4},
        {:line, 3},
        {:gc_bif, :bit_size, {:f, 0}, 2, [x: 0], {:x, 2}},
        {:line, 0},
        {:gc_bif, :div, {:f, 0}, 3, [x: 2, integer: 8], {:x, 2}},
        {:allocate, 2, 3},
        {:move, {:x, 1}, {:y, 0}},
        {:move, {:x, 0}, {:y, 1}},
        {:move, {:x, 2}, {:x, 0}},
        :bs_init_writable,
        {:move, {:x, 0}, {:x, 1}},
        {:move, {:y, 1}, {:x, 0}},
        {:init, {:y, 1}},
        {:line, 4},
        {:call, 2, {:cow_base64url, :"-decode/2-lbc$^0/2-0-", 2}},
        {:test, :is_map, {:f, 7}, [y: 0]},
        {:get_map_elements, {:f, 7}, {:y, 0}, {:list, [atom: :padding, x: 1]}},
        {:test, :is_eq_exact, {:f, 7}, [x: 1, atom: false]},
        {:line, 5},
        {:gc_bif, :byte_size, {:f, 0}, 1, [x: 0], {:x, 1}},
        {:line, 5},
        {:gc_bif, :rem, {:f, 0}, 2, [x: 1, integer: 4], {:x, 1}},
        {:select_val, {:x, 1}, {:f, 8},
        {:list, [integer: 3, f: 6, integer: 2, f: 5, integer: 0, f: 7]}},
      {:label, 5},
        {:line, 6},
        {:bs_append, {:f, 0}, {:integer, 16}, 0, 1, 8, {:x, 0}, {:field_flags, 0},
        {:x, 0}},
        {:bs_put_string, 2, {:string, '=='}},
        {:jump, {:f, 7}},
      {:label, 6},
        {:line, 7},
        {:bs_append, {:f, 0}, {:integer, 8}, 0, 1, 8, {:x, 0}, {:field_flags, 0},
        {:x, 0}},
        {:bs_put_string, 1, {:string, '='}},
      {:label, 7},
        {:line, 8},
        {:call_ext_last, 1, {:extfunc, :base64, :decode, 1}, 2},
      {:label, 8},
        {:line, 5},
        {:case_end, {:x, 1}}
    ]}
    code = ""
    assert Deformulator.Function.parse(bytecode) |> to_string == code
  end
end
