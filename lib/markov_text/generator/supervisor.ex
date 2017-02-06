defmodule MarkovText.Generator.Supervisor do
  use Supervisor

  @generation_count 1_000
  @text_store MarkovText.TextStore

  def start_link do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def generate(markov_map, max_chars \\ 140) do
    spawn fn ->
      do_generate(markov_map, max_chars, @text_store, @generation_count)
    end
  end

  def init(_) do
    children = [
      worker(MarkovText.Generator.Worker, [], restart: :temporary)
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  defp do_generate(_markov_map, _max_chars, _text_store, 0), do: :ok
  defp do_generate(markov_map, max_chars, text_store, count) do
    Supervisor.start_child(__MODULE__, [markov_map, max_chars, text_store])
    IO.puts "Started #: #{(@generation_count + 1) - count}"

    do_generate(markov_map, max_chars, text_store, count - 1)
  end
end
