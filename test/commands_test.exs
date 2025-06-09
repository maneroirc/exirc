defmodule ExIRC.CommandsTest do
  use ExUnit.Case, async: true
  use ExIRC.Commands

  test "Commands are formatted properly" do
    expected = <<0o001, "TESTCMD", 0o001, ?\r, ?\n>>
    assert expected == "TESTCMD" |> ctcp!() |> IO.iodata_to_binary()
    expected = <<"PRIVMSG #testchan :", 0o001, "ACTION mind explodes!!", 0o001, ?\r, ?\n>>
    assert expected == "#testchan" |> me!("mind explodes!!") |> IO.iodata_to_binary()
    expected = <<"PASS testpass", ?\r, ?\n>>
    assert expected == "testpass" |> pass!() |> IO.iodata_to_binary()
    expected = <<"NICK testnick", ?\r, ?\n>>
    assert expected == "testnick" |> nick!() |> IO.iodata_to_binary()
    expected = <<"USER testuser 0 * :Test User", ?\r, ?\n>>
    assert expected == "testuser" |> user!("Test User") |> IO.iodata_to_binary()
    expected = <<"PONG testnick", ?\r, ?\n>>
    assert expected == "testnick" |> pong1!() |> IO.iodata_to_binary()
    expected = <<"PONG testnick othernick", ?\r, ?\n>>
    assert expected == "testnick" |> pong2!("othernick") |> IO.iodata_to_binary()
    expected = <<"PRIVMSG testnick :Test message!", ?\r, ?\n>>
    assert expected == "testnick" |> privmsg!("Test message!") |> IO.iodata_to_binary()
    expected = <<"NOTICE testnick :Test notice!", ?\r, ?\n>>
    assert expected == "testnick" |> notice!("Test notice!") |> IO.iodata_to_binary()
    expected = <<"JOIN testchan", ?\r, ?\n>>
    assert expected == "testchan" |> join!() |> IO.iodata_to_binary()
    expected = <<"JOIN testchan chanpass", ?\r, ?\n>>
    assert expected == "testchan" |> join!("chanpass") |> IO.iodata_to_binary()
    expected = <<"PART testchan", ?\r, ?\n>>
    assert expected == "testchan" |> part!() |> IO.iodata_to_binary()
    expected = <<"QUIT :Leaving", ?\r, ?\n>>
    assert expected == IO.iodata_to_binary(quit!())
    expected = <<"QUIT :Goodbye, cruel world.", ?\r, ?\n>>
    assert expected == "Goodbye, cruel world." |> quit!() |> IO.iodata_to_binary()
    expected = <<"KICK #testchan testuser", ?\r, ?\n>>
    assert expected == "#testchan" |> kick!("testuser") |> IO.iodata_to_binary()
    expected = <<"KICK #testchan testuser Get outta here!", ?\r, ?\n>>
    assert expected == "#testchan" |> kick!("testuser", "Get outta here!") |> IO.iodata_to_binary()
    expected = <<"MODE testuser -o", ?\r, ?\n>>
    assert expected == "testuser" |> mode!("-o") |> IO.iodata_to_binary()
    expected = <<"MODE #testchan +im", ?\r, ?\n>>
    assert expected == "#testchan" |> mode!("+im") |> IO.iodata_to_binary()
    expected = <<"MODE #testchan +o testuser", ?\r, ?\n>>
    assert expected == "#testchan" |> mode!("+o", "testuser") |> IO.iodata_to_binary()
    expected = <<"INVITE testuser #testchan", ?\r, ?\n>>
    assert expected == "testuser" |> invite!("#testchan") |> IO.iodata_to_binary()
  end
end
