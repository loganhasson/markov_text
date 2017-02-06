defmodule MarkovText.TextStore do
  use GenServer

  @ending_punctuation [".", "?", "!"]

  def start_link do
    GenServer.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def generated_texts do
    GenServer.call(__MODULE__, {:generated_texts})
  end

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:generated_texts}, _from, state) do
    {:reply, state, state}
  end

  def handle_cast({:generated_text, text}, state) do
    case String.ends_with?(text, @ending_punctuation) do
      true ->
        IO.puts "ADDED: #{text}"
        {:noreply, [text | state]}
      false ->
        case String.match?(text, ~r/^[A-Z]/) do
          true ->
            IO.puts "ADDED: #{text}"
            {:noreply, [text | state]}
          false ->
            {:noreply, state}
        end
    end
  end
end
