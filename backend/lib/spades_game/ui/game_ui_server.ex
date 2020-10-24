defmodule SpadesGame.GameUIServer do
  @moduledoc """
  GenServer for holding GameUI state.
  """
  use GenServer
  @timeout :timer.minutes(60)

  require Logger
  alias SpadesGame.{Card, GameOptions, GameUI, GameRegistry, Groups, User}
  alias SpadesGame.{Game}

  @doc """
  start_link/3: Generates a new game server under a provided name.
  """
  @spec start_link(String.t(), User.t(), %GameOptions{}) :: {:ok, pid} | {:error, any}
  def start_link(game_name, user, %GameOptions{} = options) do
    IO.puts("gameuiserver: start_link a")
    a=GenServer.start_link(__MODULE__, {game_name, user, options}, name: via_tuple(game_name))
    IO.inspect(a)
    IO.puts("gameuiserver: start_link b")
  end

  @doc """
  via_tuple/1: Given a game name string, generate a via tuple for addressing the game.
  """
  def via_tuple(game_name),
    do: {:via, Registry, {SpadesGame.GameUIRegistry, {__MODULE__, game_name}}}

  @doc """
  gameui_pid/1: Returns the `pid` of the game server process registered
  under the given `game_name`, or `nil` if no process is registered.
  """
  def gameui_pid(game_name) do
    game_name
    |> via_tuple()
    |> GenServer.whereis()
  end

  @doc """
  state/1:  Retrieves the game state for the game under a provided name.
  """
  @spec state(String.t()) :: GameUI.t() | nil
  def state(game_name) do
    IO.puts("getting state a")
    IO.inspect(game_name)
    IO.puts("getting state b")
    IO.inspect(gameui_pid(game_name))
    IO.puts("getting state c")
    IO.inspect(GenServer.call(via_tuple(game_name), :state))
    IO.puts("getting state d")
    case gameui_pid(game_name) do
      nil -> nil
      _ -> GenServer.call(via_tuple(game_name), :state)
    end
  end

  @spec game_exists?(String.t()) :: boolean
  def game_exists?(game_name) do
    gameui_pid(game_name) != nil
  end

  @doc """
  bid/3: A player just submitted a bid.
  """
  @spec bid(String.t(), integer | :bot, integer) :: GameUI.t()
  def bid(game_name, user_id, bid_amount) do
    GenServer.call(via_tuple(game_name), {:bid, user_id, bid_amount})
  end

  @doc """
  play/3: A player just played a card.
  """
  @spec play(String.t(), integer | :bot, Card.t()) :: GameUI.t()
  def play(game_name, user_id, card) do
    GenServer.call(via_tuple(game_name), {:play, user_id, card})
  end

  @doc """
  update_groups/3: A player just moved a card.
  """
  @spec update_groups(String.t(), integer,  Groups.t()):: GameUI.t() #DragEvent.t()) :: GameUI.t()
  def update_groups(game_name, user_id, groups) do
    IO.puts("game_ui_server: update_groups")
    GenServer.call(via_tuple(game_name), {:update_groups, user_id, groups})
  end

  @doc """
  update_gameui/3: The game is updated.
  """
  @spec update_gameui(String.t(), integer,  GameUI.t()):: GameUI.t() #DragEvent.t()) :: GameUI.t()
  def update_gameui(game_name, user_id, gameui) do
    IO.puts("game_ui_server: update_gameui")
    GenServer.call(via_tuple(game_name), {:update_gameui, user_id, gameui})
  end

  @doc """
  update_card/6: A player just moved a card.
  """
  @spec update_card(String.t(), integer, Card.t(), String.t(), number, number) :: GameUI.t() #DragEvent.t()) :: GameUI.t()
  def update_card(game_name, user_id, card, group_id, stack_index, card_index) do
    IO.puts("game_ui_server: update_card")
    GenServer.call(via_tuple(game_name), {:update_card, user_id, card, group_id, stack_index, card_index})
  end

  @doc """
  toggle_exhaust/5: A player just exhausted/unexhausted a card.
  """
  @spec toggle_exhaust(String.t(), integer, Group.t(), Stack.t(), Card.t()) :: GameUI.t() #DragEvent.t()) :: GameUI.t()
  def toggle_exhaust(game_name, user_id, group, stack, card) do
    IO.puts("game_ui_server: toggle_exhaust")
    GenServer.call(via_tuple(game_name), {:toggle_exhaust, user_id, group, stack, card})
  end

  @doc """
  rewind_countdown_devtest/1: Make the "game start" countdown happen
  instantly.
  Works by moving back the "everyone sat down" timestamp by 10 minutes.
  Should be used in dev+test only.
  """
  def rewind_countdown_devtest(game_name) do
    GenServer.call(via_tuple(game_name), :rewind_countdown_devtest)
  end

  @doc """
  rewind_trickfull_devtest/1: Make a full trick advance to the next
  trick instantly.
  Should be used in dev+test only.
  """
  def rewind_trickfull_devtest(game_name) do
    GenServer.call(via_tuple(game_name), :rewind_trickfull_devtest)
  end

  @doc """
  sit/3: User is asking to sit in one of the seats.
  which_seat is "player1", "player2", "player3" or "player4".
  """
  @spec sit(String.t(), integer, String.t()) :: GameUI.t()
  def sit(game_name, user_id, which_seat) do
    GenServer.call(via_tuple(game_name), {:sit, user_id, which_seat})
  end

  @doc """
  leave/2: User just leave the room (Closed browser or clicked out).
  If they're in a seat, we need to mark them as gone.
  Maybe eventually there will be some sophisticated disconnect/reconnect
  system?
  """
  def leave(game_name, user_id) do
    GenServer.call(via_tuple(game_name), {:leave, user_id})
  end

  ## Temp function to set winner flag on a game
  def winner(game_name, winner_val) do
    GenServer.call(via_tuple(game_name), {:winner, winner_val})
  end

  #####################################
  ####### IMPLEMENTATION ##############
  #####################################

  def init({game_name, user, options = %GameOptions{}}) do
    IO.puts("game_ui_server init a")
    IO.inspect(game_name)
    gameui =
      case :ets.lookup(:game_uis, game_name) do
        [] ->
          IO.puts("case 1")
          gameui = GameUI.new(game_name, user, options)
          :ets.insert(:game_uis, {game_name, gameui})
          gameui

        [{^game_name, gameui}] ->
          IO.puts("case 2")
          gameui
      end

    IO.puts("game_ui_server init b")
    GameRegistry.add(gameui["game_name"], gameui)
    {:ok, gameui, timeout(gameui)}
  end

  def handle_call(:state, _from, state) do
    reply(state)
  end

  def handle_call(:invite_bots, _from, state) do
    IO.puts("handle call invite bots")
    push_state_to_clients_for_12_seconds()

    GameUI.invite_bots(state)
    |> save_and_reply()
  end

  def handle_call(:bots_leave, _from, state) do
    IO.puts("handle call bots leave")
    push_state_to_clients(3, 1000)

    GameUI.bots_leave(state)
    |> save_and_reply()
  end

  def handle_call(:bot_notify, _from, state) do
    IO.puts("handle call bot notify")
    push_state_to_clients(1, 0)

    state
    |> save_and_reply()
  end

  def handle_call({:update_groups, user_id, groups}, _from, gameui) do
    IO.puts("game_ui_server: handle_call: update_groups a")
    gameui = GameUI.update_groups(gameui, user_id, groups)
    IO.puts("game_ui_server: handle_call: update_groups b")
    gameui
    |> save_and_reply()
  end

  def handle_call({:update_gameui, user_id, updated_gameui}, _from, gameui) do
    IO.puts("game_ui_server: handle_call: update_gameui a")
    IO.puts("game_ui_server: handle_call: update_gameui b")
    updated_gameui
    |> save_and_reply()
  end

  def handle_call({:update_card, user_id, card, group_id, stack_index, card_index}, _from, gameui) do
    IO.puts("game_ui_server: handle_call: update_card a")

    IO.inspect(gameui["game"]["groups"][group_id]["stacks"][stack_index]["cards"][card_index])
    put_in(gameui["game"]["groups"][group_id]["stacks"][stack_index]["cards"][card_index],card)
    IO.puts("game_ui_server: handle_call: update_card b")
    |> save_and_reply()
  end

  def handle_call({:toggle_exhaust, user_id, group, stack, card}, _from, gameui) do
    IO.puts("game_ui_server: handle_call: toggle_exhaust a")
    gameui = GameUI.toggle_exhaust(gameui, user_id, group, stack, card)
    IO.puts("game_ui_server: handle_call: toggle_exhaust b")
    gameui
    |> save_and_reply()
  end

  def handle_call({:sit, user_id, which_seat}, _from, gameui) do
    new_gameui = GameUI.sit(gameui, user_id, which_seat)

    if new_gameui.when_seats_full != nil do
      push_state_to_clients_for_12_seconds()
    end

    save_and_reply(new_gameui)
  end

  def handle_call({:leave, user_id}, _from, gameui) do
    GameUI.leave(gameui, user_id)
    |> save_and_reply()
  end

  # def handle_call({:winner, winner_val}, _from, gameui) do
  #   game = gameui.game
  #   game = %Game{game | winner: winner_val}

  #   %GameUI{gameui | game: game}
  #   |> save_and_reply()
  # end

  defp reply(new_gameui) do
    {:reply, new_gameui, new_gameui, timeout(new_gameui)}
  end

  defp save_and_reply(new_gameui) do
    # Async GameRegistry.update Should improve performance,
    # but causes tests to fail.  Not sure it's a real failure
    # spawn_link(fn ->

    IO.puts("game_ui_server: save_and_reply a")
    #IO.inspect(new_gameui)
    GameRegistry.update(new_gameui["game_name"], new_gameui)

    IO.puts("game_ui_server: save_and_reply b")
    # end)

    spawn_link(fn ->
      :ets.insert(:game_uis, {new_gameui["game_name"], new_gameui})
    end)

    IO.puts("game_ui_server: save_and_reply c")
    IO.inspect(new_gameui)
    {:reply, new_gameui, new_gameui, timeout(new_gameui)}
  end

  # This is to handle the "Game Start" countdown.
  # 10 seconds after everyone sits down, the game begins.
  # We will spawn a process that calls ":state" every second
  # and pushes that state down to the clients, so they will see
  # the game status move to playing after 10 seconds.
  defp push_state_to_clients_for_12_seconds() do
    IO.puts("push state to clients for 12")
    {:ok} #push_state_to_clients(12, 1000)
  end

  defp push_state_to_clients(repeat_times, delay_ms) do
    IO.puts("push state to clients")
    pid = self()

    spawn_link(fn ->
      1..repeat_times
      |> Enum.each(fn _ ->
        Process.sleep(delay_ms)
        state = GenServer.call(pid, :state)
        SpadesWeb.RoomChannel.notify_from_outside(state["game_name"])
      end)
    end)
  end

  # timeout/1
  # Given the current state of the game, what should the
  # GenServer timeout be? (Games with winners expire quickly)
  defp timeout(_state) do
    IO.inspect("timeout set")
    @timeout
  end

  # When timing out, the order is handle_info(:timeout, _) -> terminate({:shutdown, :timeout}, _)
  def handle_info(:timeout, state) do
    IO.inspect("gameuiserv handle_info")
    {:stop, {:shutdown, :timeout}, state}
  end

  def terminate({:shutdown, :timeout}, state) do
    IO.inspect("gameuiserv shutdown")
    Logger.info("Terminate (Timeout) running for #{state["game_name"]}")
    :ets.delete(:game_uis, state["game_name"])
    GameRegistry.remove(state["game_name"])
    :ok
  end

  # Do I need to trap exits here?
  def terminate(_reason, state) do
    IO.puts("terminating because")
    IO.inspect(_reason)
    Logger.info("Terminate (Non Timeout) running for #{state["game_name"]}")
    GameRegistry.remove(state["game_name"])
    :ok
  end
end




# defmodule SpadesGame.GameUIServer do
#   @moduledoc """
#   GenServer for holding GameUI state.
#   """
#   use GenServer
#   @timeout :timer.minutes(60)

#   require Logger
#   alias SpadesGame.{Card, GameOptions, GameUI, GameRegistry, Groups}
#   alias SpadesGame.{Game}

#   @doc """
#   start_link/2: Generates a new game server under a provided name.
#   """
#   @spec start_link(String.t(), %GameOptions{}) :: {:ok, pid} | {:error, any}
#   def start_link(game_name, %GameOptions{} = options) do
#     GenServer.start_link(__MODULE__, {game_name, options}, name: via_tuple(game_name))
#   end

#   @doc """
#   via_tuple/1: Given a game name string, generate a via tuple for addressing the game.
#   """
#   def via_tuple(game_name),
#     do: {:via, Registry, {SpadesGame.GameUIRegistry, {__MODULE__, game_name}}}

#   @doc """
#   gameui_pid/1: Returns the `pid` of the game server process registered
#   under the given `game_name`, or `nil` if no process is registered.
#   """
#   def gameui_pid(game_name) do
#     game_name
#     |> via_tuple()
#     |> GenServer.whereis()
#   end

#   @doc """
#   state/1:  Retrieves the game state for the game under a provided name.
#   """
#   @spec state(String.t()) :: GameUI.t() | nil
#   def state(game_name) do
#     case gameui_pid(game_name) do
#       nil -> nil
#       _ -> GenServer.call(via_tuple(game_name), :state)
#     end
#   end

#   @spec game_exists?(String.t()) :: boolean
#   def game_exists?(game_name) do
#     gameui_pid(game_name) != nil
#   end

#   @doc """
#   bid/3: A player just submitted a bid.
#   """
#   @spec bid(String.t(), integer | :bot, integer) :: GameUI.t()
#   def bid(game_name, user_id, bid_amount) do
#     GenServer.call(via_tuple(game_name), {:bid, user_id, bid_amount})
#   end

#   @doc """
#   play/3: A player just played a card.
#   """
#   @spec play(String.t(), integer | :bot, Card.t()) :: GameUI.t()
#   def play(game_name, user_id, card) do
#     GenServer.call(via_tuple(game_name), {:play, user_id, card})
#   end

#   @doc """
#   update_groups/3: A player just moved a card.
#   """
#   @spec update_groups(String.t(), integer,  Groups.t()):: GameUI.t() #DragEvent.t()) :: GameUI.t()
#   def update_groups(game_name, user_id, groups) do
#     IO.puts("game_ui_server: update_groups")
#     GenServer.call(via_tuple(game_name), {:update_groups, user_id, groups})
#   end

#   @doc """
#   update_card/7: A player just moved a card.
#   """
#   @spec update_card(String.t(), integer, Card.t(), String.t(), number, number, String.t()) :: GameUI.t() #DragEvent.t()) :: GameUI.t()
#   def update_card(game_name, user_id, card, group_id, stack_index, card_index, temp) do
#     IO.puts("game_ui_server: update_card")
#     IO.puts(temp)
#     GenServer.call(via_tuple(game_name), {:update_card, user_id, card, group_id, stack_index, card_index})
#   end

#   @doc """
#   toggle_exhaust/5: A player just exhausted/unexhausted a card.
#   """
#   @spec toggle_exhaust(String.t(), integer, Group.t(), Stack.t(), Card.t()) :: GameUI.t() #DragEvent.t()) :: GameUI.t()
#   def toggle_exhaust(game_name, user_id, group, stack, card) do
#     IO.puts("game_ui_server: toggle_exhaust")
#     GenServer.call(via_tuple(game_name), {:toggle_exhaust, user_id, group, stack, card})
#   end

#   @doc """
#   rewind_countdown_devtest/1: Make the "game start" countdown happen
#   instantly.
#   Works by moving back the "everyone sat down" timestamp by 10 minutes.
#   Should be used in dev+test only.
#   """
#   def rewind_countdown_devtest(game_name) do
#     GenServer.call(via_tuple(game_name), :rewind_countdown_devtest)
#   end

#   @doc """
#   rewind_trickfull_devtest/1: Make a full trick advance to the next
#   trick instantly.
#   Should be used in dev+test only.
#   """
#   def rewind_trickfull_devtest(game_name) do
#     GenServer.call(via_tuple(game_name), :rewind_trickfull_devtest)
#   end

#   @doc """
#   sit/3: User is asking to sit in one of the seats.
#   which_seat is "north", "west", "east" or "south".
#   """
#   @spec sit(String.t(), integer, String.t()) :: GameUI.t()
#   def sit(game_name, user_id, which_seat) do
#     GenServer.call(via_tuple(game_name), {:sit, user_id, which_seat})
#   end

#   @doc """
#   leave/2: User just leave the room (Closed browser or clicked out).
#   If they're in a seat, we need to mark them as gone.
#   Maybe eventually there will be some sophisticated disconnect/reconnect
#   system?
#   """
#   def leave(game_name, user_id) do
#     GenServer.call(via_tuple(game_name), {:leave, user_id})
#   end

#   ## Temp function to set winner flag on a game
#   def winner(game_name, winner_val) do
#     GenServer.call(via_tuple(game_name), {:winner, winner_val})
#   end

#   #####################################
#   ####### IMPLEMENTATION ##############
#   #####################################

#   def init({game_name, options = %GameOptions{}}) do
#     gameui =
#       case :ets.lookup(:game_uis, game_name) do
#         [] ->
#           gameui = GameUI.new(game_name, options)
#           :ets.insert(:game_uis, {game_name, gameui})
#           gameui

#         [{^game_name, gameui}] ->
#           gameui
#       end

#     GameRegistry.add(gameui.game_name, gameui)
#     {:ok, gameui, timeout(gameui)}
#   end

#   def handle_call(:state, _from, state) do
#     GameUI.checks(state)
#     |> reply()
#   end

#   def handle_call(:rewind_countdown_devtest, _from, state) do
#     GameUI.rewind_countdown_devtest(state)
#     |> save_and_reply()
#   end

#   def handle_call(:rewind_trickfull_devtest, _from, state) do
#     GameUI.rewind_trickfull_devtest(state)
#     |> save_and_reply()
#   end

#   def handle_call(:invite_bots, _from, state) do
#     push_state_to_clients_for_12_seconds()

#     GameUI.invite_bots(state)
#     |> save_and_reply()
#   end

#   def handle_call(:bots_leave, _from, state) do
#     push_state_to_clients(3, 1000)

#     GameUI.bots_leave(state)
#     |> save_and_reply()
#   end

#   def handle_call(:bot_notify, _from, state) do
#     push_state_to_clients(1, 0)

#     state
#     |> save_and_reply()
#   end

#   def handle_call({:bid, user_id, bid_amount}, _from, gameui) do
#     GameUI.bid(gameui, user_id, bid_amount)
#     |> save_and_reply()
#   end

#   def handle_call({:play, user_id, card}, _from, gameui) do
#     gameui = GameUI.play(gameui, user_id, card)

#     # A full trick takes a little while to go away
#     if GameUI.trick_full?(gameui) do
#       push_state_to_clients(2, 700)
#     end

#     gameui
#     |> save_and_reply()
#   end

#   def handle_call({:update_groups, user_id, groups}, _from, gameui) do
#     IO.puts("game_ui_server: handle_call: update_groups a")
#     gameui = GameUI.update_groups(gameui, user_id, groups)
#     IO.puts("game_ui_server: handle_call: update_groups b")
#     gameui
#     |> save_and_reply()
#   end

#   def handle_call({:update_card, user_id, card, group_id, stack_index, card_index}, _from, gameui) do
#     IO.puts("game_ui_server: handle_call: update_card a")
#     gameui = GameUI.update_card(gameui, user_id, card, group_id, stack_index, card_index)
#     IO.puts("game_ui_server: handle_call: update_card b")
#     gameui
#     |> save_and_reply()
#   end

#   def handle_call({:toggle_exhaust, user_id, group, stack, card}, _from, gameui) do
#     IO.puts("game_ui_server: handle_call: toggle_exhaust a")
#     gameui = GameUI.toggle_exhaust(gameui, user_id, group, stack, card)
#     IO.puts("game_ui_server: handle_call: toggle_exhaust b")
#     gameui
#     |> save_and_reply()
#   end

#   def handle_call({:sit, user_id, which_seat}, _from, gameui) do
#     new_gameui = GameUI.sit(gameui, user_id, which_seat)

#     if new_gameui.when_seats_full != nil do
#       push_state_to_clients_for_12_seconds()
#     end

#     save_and_reply(new_gameui)
#   end

#   def handle_call({:leave, user_id}, _from, gameui) do
#     GameUI.leave(gameui, user_id)
#     |> save_and_reply()
#   end

#   def handle_call({:winner, winner_val}, _from, gameui) do
#     game = gameui.game
#     game = %Game{game | winner: winner_val}

#     %GameUI{gameui | game: game}
#     |> save_and_reply()
#   end

#   defp reply(new_gameui) do
#     {:reply, new_gameui, new_gameui, timeout(new_gameui)}
#   end

#   defp save_and_reply(new_gameui) do
#     # Async GameRegistry.update Should improve performance,
#     # but causes tests to fail.  Not sure it's a real failure
#     # spawn_link(fn ->

#     IO.puts("game_ui_server: save_and_reply a")
#     #IO.inspect(new_gameui)
#     GameRegistry.update(new_gameui.game_name, new_gameui)

#     IO.puts("game_ui_server: save_and_reply b")
#     # end)

#     spawn_link(fn ->
#       :ets.insert(:game_uis, {new_gameui.game_name, new_gameui})
#     end)

#     IO.puts("game_ui_server: save_and_reply c")
#     {:reply, new_gameui, new_gameui, timeout(new_gameui)}
#   end

#   # This is to handle the "Game Start" countdown.
#   # 10 seconds after everyone sits down, the game begins.
#   # We will spawn a process that calls ":state" every second
#   # and pushes that state down to the clients, so they will see
#   # the game status move to playing after 10 seconds.
#   defp push_state_to_clients_for_12_seconds() do
#     push_state_to_clients(12, 1000)
#   end

#   defp push_state_to_clients(repeat_times, delay_ms) do
#     pid = self()

#     spawn_link(fn ->
#       1..repeat_times
#       |> Enum.each(fn _ ->
#         Process.sleep(delay_ms)
#         state = GenServer.call(pid, :state)
#         SpadesWeb.RoomChannel.notify_from_outside(state.game_name)
#       end)
#     end)
#   end

#   # timeout/1
#   # Given the current state of the game, what should the
#   # GenServer timeout be? (Games with winners expire quickly)
#   defp timeout(_state) do
#     @timeout
#   end

#   # When timing out, the order is handle_info(:timeout, _) -> terminate({:shutdown, :timeout}, _)
#   def handle_info(:timeout, state) do
#     {:stop, {:shutdown, :timeout}, state}
#   end

#   def terminate({:shutdown, :timeout}, state) do
#     Logger.info("Terminate (Timeout) running for #{state.game_name}")
#     :ets.delete(:game_uis, state.game_name)
#     GameRegistry.remove(state.game_name)
#     :ok
#   end

#   # Do I need to trap exits here?
#   def terminate(_reason, state) do
#     Logger.info("Terminate (Non Timeout) running for #{state.game_name}")
#     GameRegistry.remove(state.game_name)
#     :ok
#   end
# end
