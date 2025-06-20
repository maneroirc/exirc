defmodule ExIRC.Utils do
  ######################
  # IRC Message Parsing
  ######################
  @moduledoc false
  alias ExIRC.Client.ClientState

  @doc """
  Parse an IRC message

  Example:

      data    = ':irc.example.org 005 nick NETWORK=Freenode PREFIX=(ov)@+ CHANTYPES=#&'
      message = ExIRC.Utils.parse data
      assert "irc.example.org" = message.server
  """

  @spec parse(raw_data :: charlist) :: ExIRC.Message.t()

  def parse(raw_data) do
    data = :string.substr(raw_data, 1, length(raw_data))

    case data do
      [?: | _] ->
        [[?: | from] | rest] = :string.tokens(data, ~c" ")
        get_cmd(rest, parse_from(from, %ExIRC.Message{ctcp: false}))

      data ->
        get_cmd(:string.tokens(data, ~c" "), %ExIRC.Message{ctcp: false})
    end
  end

  @prefix_pattern ~r/^(?<nick>[^!\s]+)(?:!(?:(?<user>[^@\s]+)@)?(?:(?<host>[\S]+)))?$/
  defp parse_from(from, msg) do
    from_str = IO.iodata_to_binary(from)
    parts = Regex.run(@prefix_pattern, from_str, capture: :all_but_first)

    case parts do
      [nick, user, host] ->
        %{msg | nick: nick, user: user, host: host}

      [nick, host] ->
        %{msg | nick: nick, host: host}

      [nick] ->
        if String.contains?(nick, ".") do
          %{msg | server: nick}
        else
          %{msg | nick: nick}
        end
    end
  end

  # Parse command from message
  defp get_cmd([cmd, arg1, [?:, 1 | ctcp_trail] | restargs], msg) when cmd == ~c"PRIVMSG" or cmd == ~c"NOTICE" do
    get_cmd([cmd, arg1, [1 | ctcp_trail] | restargs], msg)
  end

  defp get_cmd([cmd, target, [1 | ctcp_cmd] | cmd_args], msg) when cmd == ~c"PRIVMSG" or cmd == ~c"NOTICE" do
    args =
      cmd_args
      |> Enum.map(&Enum.take_while(&1, fn c -> c != 0o001 end))
      |> Enum.map(&List.to_string/1)

    case args do
      args when args != [] ->
        %{
          msg
          | cmd: to_string(ctcp_cmd),
            args: [to_string(target), Enum.join(args, " ")],
            ctcp: true
        }

      _ ->
        %{msg | cmd: to_string(cmd), ctcp: :invalid}
    end
  end

  defp get_cmd([cmd | rest], msg) do
    get_args(rest, %{msg | cmd: to_string(cmd)})
  end

  # Parse command args from message
  defp get_args([], msg) do
    args =
      msg.args
      |> Enum.reverse()
      |> Enum.filter(fn arg -> arg != [] end)
      |> Enum.map(&trim_crlf/1)
      |> Enum.map(&:binary.list_to_bin/1)
      |> Enum.map(fn s ->
        if String.valid?(s) do
          :unicode.characters_to_binary(s)
        else
          :unicode.characters_to_binary(s, :latin1, :unicode)
        end
      end)

    post_process(%{msg | args: args})
  end

  defp get_args([[?: | first_arg] | rest], msg) do
    for_result = for(arg <- [first_arg | rest], do: ~c" " ++ trim_crlf(arg))
    args = List.flatten(for_result)

    case args do
      [_] ->
        get_args([], %{msg | args: msg.args})

      [_ | full_trail] ->
        get_args([], %{msg | args: [full_trail | msg.args]})
    end
  end

  defp get_args([arg | rest], msg) do
    get_args(rest, %{msg | args: [arg | msg.args]})
  end

  # This function allows us to handle special case messages which are not RFC
  # compliant, before passing it to the client.
  defp post_process(%ExIRC.Message{cmd: "332", args: [nick, channel]} = msg) do
    # Handle malformed RPL_TOPIC messages which contain no topic
    %{msg | :cmd => "331", :args => [channel, "No topic is set"], :nick => nick}
  end

  defp post_process(msg), do: msg

  ############################
  # Parse RPL_ISUPPORT (005)
  ############################

  @doc """
  Parse RPL_ISUPPORT message.

  If an empty list is provided, do nothing, otherwise parse CHANTYPES,
  NETWORK, and PREFIX parameters for relevant data.
  """
  @spec isup(parameters :: list(binary), state :: ClientState.t()) ::
          ClientState.t()
  def isup([], state), do: state

  def isup([param | rest], state) do
    isup(rest, isup_param(param, state))
  rescue
    _ -> isup(rest, state)
  end

  defp isup_param("CHANTYPES=" <> channel_prefixes, state) do
    prefixes = String.split(channel_prefixes, "", trim: true)
    %{state | channel_prefixes: prefixes}
  end

  defp isup_param("NETWORK=" <> network, state) do
    %{state | network: network}
  end

  defp isup_param("PREFIX=" <> user_prefixes, state) do
    prefixes =
      ~r/\((.*)\)(.*)/
      |> Regex.run(user_prefixes, capture: :all_but_first)
      |> Enum.map(&String.to_charlist/1)
      |> Enum.zip()

    %{state | user_prefixes: prefixes}
  end

  defp isup_param(_, state) do
    state
  end

  ###################
  # Helper Functions
  ###################

  @days_of_week [~c"Mon", ~c"Tue", ~c"Wed", ~c"Thu", ~c"Fri", ~c"Sat", ~c"Sun"]
  @months_of_year [
    ~c"Jan",
    ~c"Feb",
    ~c"Mar",
    ~c"Apr",
    ~c"May",
    ~c"Jun",
    ~c"Jul",
    ~c"Aug",
    ~c"Sep",
    ~c"Oct",
    ~c"Nov",
    ~c"Dec"
  ]
  @doc """
  Get CTCP formatted time from a tuple representing the current calendar time:

  Example:

      iex> local_time = {{2013,12,6},{14,5,0}}
      {{2013,12,6},{14,5,0}}
      iex> ExIRC.Utils.ctcp_time local_time
      "Fri Dec 06 14:05:00 2013"
  """
  @spec ctcp_time(datetime :: {{integer, integer, integer}, {integer, integer, integer}}) ::
          binary
  def ctcp_time({{y, m, d}, {h, n, s}} = _datetime) do
    [
      :lists.nth(:calendar.day_of_the_week(y, m, d), @days_of_week),
      ~c" ",
      :lists.nth(m, @months_of_year),
      ~c" ",
      :io_lib.format("~2..0s", [Integer.to_charlist(d)]),
      ~c" ",
      :io_lib.format("~2..0s", [Integer.to_charlist(h)]),
      ~c":",
      :io_lib.format("~2..0s", [Integer.to_charlist(n)]),
      ~c":",
      :io_lib.format("~2..0s", [Integer.to_charlist(s)]),
      ~c" ",
      Integer.to_charlist(y)
    ]
    |> List.flatten()
    |> List.to_string()
  end

  defp trim_crlf(charlist) do
    case Enum.reverse(charlist) do
      [?\n, ?\r | text] -> Enum.reverse(text)
      _ -> charlist
    end
  end
end
