defmodule Deformulator.Register do
  @moduledoc """
  Used to represent the register of the BEAM VM and map it to variables.
  """

  defstruct variables: %{}, tracker: 0

  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###
  ### PUBLIC API
  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###

  @doc """
  Creates a variable with the given name or in the given register.

  ## Paramters

    * reg - The register.
    * name - The name of the variable - or the `{register, slot}`. If not specified `"anon"` is used.

  ## Returns

    * A tuple with the new register as first element and the variable name as second.

  ## Example

      iex> Deformulator.Register.create_variable(%Deformulator.Register{}, "myvar")
      {%Deformulator.Register{}, "var0_u_myvar"}
      iex> Deformulator.Register.create_variable(%Deformulator.Register{}, {:x, 0})
      {%Deformulator.Register{}, "var0_x0"}
      iex> Deformulator.Register.create_variable(%Deformulator.Register{})
      {%Deformulator.Register{}, "var0_u_anon"}
  """
  def create_variable(reg, name \\ "anon")
  def create_variable(reg, name) when is_binary(name), do: varname(reg, "u_" <> name)
  def create_variable(reg, {register_name, register_slot}) do
    {reg, name} = varname(reg, {register_name, register_slot})
    reg = put_var_in_register(reg, {register_name, register_slot}, name)
    {reg, name}
  end

  @doc """
  Registers the parameter in the register. Similar in functionality to `create_variable/3`, but the resulting
  variables differ in name aswell as have a predefined register that is being used.

  ## Parameters

    * reg - The register.
    * index - The index of the paramter. 0, 1, 2...

  ## Returns

    * A tuple with the new register as first element and the variable name as second.

  ## Example

      iex> create_parameter(%Deformulator.Register{..}, 4)
      {%Deformulator.Register{..}, "param9_x4}
  """
  def create_parameter(reg, index) do
    {reg, name} = varname(reg, {:x, index}, "param")
    reg = put_var_in_register(reg, {:x, index}, name)
    {reg, name}
  end

  @doc """
  Looks through the register and tries to find the variable name currently assoicated with it.

  ## Parameters

    * reg - The register
    * register - A tuple with the regiser name and the register slot

  ## Returns

    * The variable name as string or `nil`.

  ## Example

      iex> find_variable(%Deformulator.Register{..}, {:y, 1})
      "var3_y1"
      iex> find_variable(%Deformulator.Register{..}, {:x, 7})
      nil
  """
  def find_variable(reg, {register_name, register_slot}) do
    Map.get(reg.variables, {register_name, register_slot})
  end

  @doc """
  Finds the given variable or raises a `RegisterNotFoundError`.

  ## Parameters

    * reg - The register
    * register - A tuple with the regiser name and the register slot

  ## Returns

    * The variable name as string.

  ## Example

      iex> find_variable(%Deformulator.Register{..}, {:y, 1})
      "var3_y1"
      iex> find_variable(%Deformulator.Register{..}, {:x, 7})
      # RegisterNotFoundError - The given register could not be found.
  """
  def find_variable!(reg, register) do
    case find_variable(reg, register) do
      nil -> raise Deformulator.Register.RegisterNotFoundError, register: register
      var -> var
    end
  end

  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###
  ### PRIVATE API
  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###

  ## Assoicates the given variable name with the given register.
  defp put_var_in_register(reg, register, var), do: %Deformulator.Register{reg | variables: Map.put(reg.variables, register, var)}

  ## Creates a variable name for the current reigster.
  defp varname(reg, name, prefix \\ "var")
  defp varname(reg, {register_name, register_slot}, prefix), do: varname(reg, "#{register_name}#{register_slot}", prefix)
  defp varname(reg, name, prefix) do
    {%Deformulator.Register{reg | tracker: reg.tracker + 1}, "#{prefix}#{reg.tracker}_#{name}"}
  end

  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###
  ### EXCEPTIONS
  ###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###-###

  defmodule RegisterNotFoundError do
    @moduledoc """
    This excpetion is used to signal the unexpected absence of a register entry.
    """

    defexception message: "The given register could not be found.", register: nil

    def message(e) do
      "#{e.message} (Register: #{inspect e.register})"
    end
  end
end
