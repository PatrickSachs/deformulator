defmodule Deformulator.MixProject do
  use Mix.Project

  def project() do
    [
      app: :deformulator,
      version: "0.1.0",
      elixir: "~> 1.10",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  def application() do
    [
      extra_applications: [:logger],
      mod: {Deformulator.Application, []}
    ]
  end

  defp deps() do
    [
    ]
  end
end
