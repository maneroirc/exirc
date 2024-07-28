defmodule ExIRC.Message do
  defstruct server: ~c"",
            nick: ~c"",
            user: ~c"",
            host: ~c"",
            ctcp: nil,
            cmd: ~c"",
            args: []
end
