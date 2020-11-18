defmodule Membrane.RTP.AAC.MixProject do
  use Mix.Project

  @version "0.1.0-alpha"
  @github_url "https://github.com/membraneframework/membrane_rtp_aac_plugin"

  def project do
    [
      app: :membrane_rtp_aac_plugin,
      version: @version,
      elixir: "~> 1.9",
      elixirc_paths: elixirc_paths(Mix.env()),
      description: "Membrane Multimedia Framework (RTP AAC Plugin)",
      package: package(),
      name: "Membrane Plugin: RTP AAC",
      source_url: @github_url,
      docs: docs(),
      deps: deps()
    ]
  end

  def application do
    [
      extra_applications: []
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  defp docs do
    [
      main: "readme",
      extras: ["README.md"],
      source_ref: "v#{@version}",
      nest_modules_by_prefix: [Membrane.RTP.AAC]
    ]
  end

  defp package do
    [
      maintainers: ["Membrane Team"],
      licenses: ["Apache 2.0"],
      links: %{
        "GitHub" => @github_url,
        "Membrane Framework Homepage" => "https://membraneframework.org"
      }
    ]
  end

  defp deps do
    [
      {:membrane_core, "~> 0.5.1"},
      {:membrane_aac_format, "~> 0.1.0"},
      {:membrane_remote_stream_format, "~> 0.1.0"},
      {:membrane_rtp_format, github: "membraneframework/membrane_rtp_format", branch: :develop},
      {:ex_doc, "~> 0.21", only: [:dev, :test], runtime: false},
      {:dialyxir, "~> 1.0", only: :dev, runtime: false}
    ]
  end
end
