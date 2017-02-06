defmodule MarkovText.Consumer do
  use GenServer

  def start_link(chain_length \\ 3) do
    GenServer.start_link(__MODULE__, chain_length, name: __MODULE__)
  end

  def consume_text(arg, arg_type \\ :text) do
    GenServer.call(__MODULE__, {:consume_text, arg, arg_type})
  end

  def markov_map do
    GenServer.call(__MODULE__, {:markov_map})
  end

  def init(chain_length) do
    {:ok, %{chain_length: chain_length, markov_map: %{}}}
  end

  def handle_call({:markov_map}, _from, %{markov_map: markov_map} = state) do
    {:reply, markov_map, state}
  end

  def handle_call({:consume_text, text, :text}, _from, %{chain_length: chain_length, markov_map: markov_map} = state) do
    updated_markov_map = handle_text(text, markov_map, chain_length)
    {:reply, :ok, Map.put(state, :markov_map, updated_markov_map)}
  end

  def handle_call({:consume_text, file_path, :file_path}, _from, %{chain_length: chain_length, markov_map: markov_map} = state) do
    {:ok, text} = File.read(file_path)

    case File.read(file_path) do
      {:ok, text} ->
        updated_markov_map = handle_text(text, markov_map, chain_length)
        {:reply, :ok, Map.put(state, :markov_map, updated_markov_map)}
      {:error, _} -> IO.puts "There was a problem reading that file."
        {:reply, :ok, state}
    end
  end

  defp handle_text(text, markov_map, chain_length) do
    consumed_map =
      text
      |> String.split
      |> consume_tokens(chain_length)

    updated_markov_map = Map.merge(markov_map, consumed_map, fn (_k, v1, v2) ->
      v1 ++ v2
    end)
  end

  defp consume_tokens(tokens, chain_length), do: do_consume_tokens(tokens, %{}, chain_length)

  defp do_consume_tokens([], map, _chain_length), do: map
  defp do_consume_tokens([_head | tail] = tokens, map, chain_length) do
    {key, value} =
      Enum.take(tokens, chain_length + 1)
      |> handle_chunk(chain_length)

    new_map = case {key, value} do
      {nil, nil} ->
        map
      {^key, ^value} ->
        Map.update(map, key, [value], &(&1 ++ [value]))
    end

    do_consume_tokens(tail, new_map, chain_length)
  end

  defp handle_chunk(chunk, chain_length) when length(chunk) == chain_length + 1 do
    [value | key] = Enum.reverse(chunk)

    {Enum.reverse(key), value}
  end
  defp handle_chunk(_chunk, _chain_length) do
    {nil, nil}
  end
end
