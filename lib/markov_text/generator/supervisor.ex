defmodule MarkovText.Generator.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def generate(count \\ 1_000) do
    spawn fn ->
      do_generate(count)
    end
  end

  def init(_) do
    children = [
      :poolboy.child_spec(pool_name, poolboy_config, [])
    ]

    supervise(children, strategy: :one_for_one)
  end

  defp do_generate(0), do: :ok
  defp do_generate(count) do
    spawn fn ->
      worker = :poolboy.checkout(:markov_pool, true, :infinity)
      IO.puts "Started #: #{(@generation_count + 1) - count}"
      GenServer.call(worker, {:generate_text}, :infinity)
      :poolboy.checkin(:markov_pool, worker)
    end

    do_generate(count - 1)
  end

  defp pool_name, do: :markov_pool

  defp poolboy_config do
   [name: {:local, pool_name},
    worker_module: MarkovText.Generator.Worker,
    size: 10,
    max_overflow: 0]
  end
end
