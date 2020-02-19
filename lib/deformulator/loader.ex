defmodule Deformulator.Loader do
  @doc """
  Disassembles the raw binary data of a beam file into a data format usage by the decompiler.

  ## Paramters
    * file_string - The raw data retrieved from e.g. `File.read/1`.

  ## Returns
    * {:ok, bytecode} - The bytecode

  ## Example
    iex> load_beam(<<70, 79, 82, 49, 0, ..>>)
    {:ok, {:beam_file, :test, [{:module_info, 0, 5}, {:module_info, 1, 7}, {:my_fun, 2, 2}], ..}}
  """
  def load_beam(file_string) do
    {:ok, :beam_disasm.file(file_string)}
  end

  def load_beam!(file_string) do
    case load_beam(file_string) do
      {:ok, beam} -> beam
    end
  end

  @doc """
  Same as `load_beam/1' except that it works with files and returns and error tuple.
  """
  def load_beam_file(file_path) do
    case File.read(file_path) do
      {:ok, beam} -> load_beam(beam)
      error -> error
    end
  end

  def load_beam_file!(file_path) do
    case load_beam_file(file_path) do
      {:ok, beam} -> beam
      {:error, error} -> raise Deformulator.Errors.InvalidBeamError, file: file_path, error: error
    end
  end

  def erl_string_to_term(str) do
    {:ok, tokens, _end_line} = :erl_scan.string(:erlang.binary_to_list(str <> "."))
    {:ok, abs_form} = :erl_parse.parse_exprs(tokens)
    {:value, value, _bs} = :erl_eval.exprs(abs_form, :erl_eval.new_bindings())
    value
  end

  def term_to_ex_string(str) do
    str |> Kernel.inspect(pretty: true, limit: :infinity)
  end
end
