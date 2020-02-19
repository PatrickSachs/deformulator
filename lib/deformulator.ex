defmodule Deformulator do

  def parse(bytecode) do
    bytecode
    |> Deformulator.Module.parse
    |> Deformulator.Module.optimize
  end

  def mod_test do
    "./priv/test/test.beam.asm"
    |> File.read!
    |> Deformulator.Loader.erl_string_to_term
    |> Deformulator.Module.parse
  end

  def test do
    Deformulator.Function.parse({:function,:encode,2,12, [{:line,10},{:label,11},{:func_info,{:atom,:cow_base64url},{:atom,:encode},2},{:label,12},{:allocate,1,2},{:move,{:x,1},{:y,0}},{:call_ext,1,{:extfunc,:base64,:encode,1}},{:move,{:literal,<<>>},{:x,2}},{:move,{:y,0},{:x,1}},{:call_last,3,{:cow_base64url,:encode,3},1}]})
  end

  def test2 do
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
    Deformulator.Function.parse(bytecode)
  end

  def test3 do
    bytecode = {:function, :my_fun, 2, 2,
    [
      {:label, 1},
      {:line, 1},
      {:func_info, {:atom, :test}, {:atom, :my_fun}, 2},
      {:label, 2},
      {:put_map_assoc, {:f, 0},
       {:literal, %{key1: 'value1', key2: 'value2', key3: 'value3'}}, {:x, 0},
       2, {:list, [atom: :key4, x: 0, atom: :key5, x: 1]}},
      {:get_map_elements, {:f, 3}, {:x, 0},
       {:list, [atom: :key5, x: 2, atom: :key2, x: 1]}},
      {:test, :is_eq_exact, {:f, 3}, [x: 1, literal: 'value2']},
      {:move, {:x, 2}, {:x, 0}},
      :return,
      {:label, 3},
      {:line, 2},
      {:badmatch, {:x, 0}}
    ]}
    Deformulator.Function.parse(bytecode)
  end
end
