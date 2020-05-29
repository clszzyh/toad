defmodule Hf.ApiTest do
  use ExUnit.Case, async: true
  # doctest MyModule
  use Hf.Http.Config
  alias Ecto.Adapters.SQL.Sandbox

  setup do
    # Explicitly get a connection before each test
    :ok = Sandbox.checkout(Repo)
    Sandbox.mode(Repo, {:shared, self()})
  end

  for {module, tests} <- Registry.state().tests do
    for %{name: name, pattern: ast} = t <- tests do
      test_name = "#{Registry.name(module)} : #{name}"

      assert_ast =
        quote do
          test unquote(test_name) do
            assert unquote(ast) = Core.do_test(unquote(Macro.escape(t)), unquote(module))
          end
        end

      Module.eval_quoted(__MODULE__, assert_ast)
    end
  end
end
