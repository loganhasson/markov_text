defmodule MarkovText.Generator.Worker do
  use GenServer

  @consumer MarkovText.Consumer
  @text_store MarkovText.TextStore
  @max_chars 140

  def start_link(_arg) do
    GenServer.start_link(__MODULE__, :ok, [])
  end

  def init(:ok) do
    send self(), {:update_markov_map}
    {:ok, %{}}
  end

  def handle_info({:update_markov_map}, state) do
    case GenServer.call(@consumer, {:status}, :infinity) do
      :incomplete ->
        Process.send_after(self(), {:update_markov_map}, 200)
        {:noreply, state}
      markov_map ->
        {:noreply, markov_map}
    end
  end

  def handle_call({:generate_text}, _from, state) do
    starting_key =
      Map.keys(state)
      |> generate_starting_key

    word_list = generate_word_list(state, starting_key, @max_chars)

    GenServer.cast(@text_store, {:generated_text, Enum.join(word_list, " ")})

    IO.puts "DONE WORKING."
    {:reply, :ok, state}
  end

  defp generate_starting_key(possible_keys) do
    good_keys =
      possible_keys
      |> Enum.filter(fn ([head | tail] = key) ->
        !Enum.any?(key, &(String.ends_with?(&1, [".", "?", "!", ";"])))
      end)

    cond do
      length(good_keys) > 0 ->
        good_keys |> Enum.random
      true ->
        List.first(possible_keys)
    end
  end

  defp generate_word_list(markov_map, key, max_chars) do
    do_generate_word_list(markov_map, key, [], max_chars)
  end

  defp do_generate_word_list(markov_map, [word | tail] = key, word_list, max_chars) do
    current_length =
      word_list
      |> Enum.join(" ")
      |> String.length

    cond do
      current_length < max_chars ->
        next_word_possibilities = markov_map[key]
        case next_word_possibilities do
          nil ->
            word_list
          _ ->
            new_key = tail ++ [Enum.random(next_word_possibilities)]
            do_generate_word_list(markov_map, new_key, word_list ++ [word], max_chars)
        end
      true ->
        word_list
    end
  end
end
