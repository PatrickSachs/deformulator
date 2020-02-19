defmodule Deformulator.Errors.InvalidBeamError do
  defexception message: "The beam file is invalid.", file: "", error: nil
end
