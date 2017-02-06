defmodule MarkovText.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    children = [
      worker(MarkovText.Consumer, []),
      worker(MarkovText.TextStore, []),
      supervisor(MarkovText.Generator.Supervisor, [])
    ]

    opts = [strategy: :one_for_one, name: MarkovText.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
