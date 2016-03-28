defmodule BlazeCloud.Mixfile do
  use Mix.Project

  def project do
    [app: :blaze_cloud,
     version: "0.0.1",
     elixir: "~> 1.2",
     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     deps: deps]
  end

  def application do
    [applications: [:logger, :httpoison]]
  end

  defp deps do
    [{:httpoison, "~> 0.8.1"},
     {:poison, "~> 2.0.1"},
     {:mock, "~> 0.1.1", only: :test}]
  end

  defp description do
    """
    Elixir Library for Backblaze B2 Cloud Storage.
    """
  end

  defp package do
    [files: ["lib", "mix.exs", "README.md", "LICENSE.md"],
     maintainers: ["David Peredo"],
     licenses: ["MIT License"],
     links: %{"Github" => "https://github.com/PerishableDave/blaze_cloud"}]
  end
end
