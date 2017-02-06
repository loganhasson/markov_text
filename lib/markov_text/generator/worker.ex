defmodule MarkovText.Generator.Worker do
  use GenServer

  def start_link(markov_map, max_chars, text_store) do
    GenServer.start_link(__MODULE__, [markov_map, max_chars, text_store])
  end

  def init([markov_map, max_chars, text_store]) do
    send self(), {:generate_text}
    {:ok, %{markov_map: markov_map, max_chars: max_chars, text_store: text_store}}
  end

  def handle_info({:generate_text}, %{markov_map: markov_map, max_chars: max_chars, text_store: text_store} = state) do
    starting_key =
      Map.keys(markov_map)
      |> generate_starting_key

    word_list = generate_word_list(markov_map, starting_key, max_chars)

    GenServer.cast(text_store, {:generated_text, Enum.join(word_list, " ")})

    IO.puts "DONE WORKING."
    {:stop, :normal, :ok}
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
