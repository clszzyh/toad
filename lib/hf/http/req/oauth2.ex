defmodule Hf.Http.Req.Oauth2 do
  use Hf.Http.Middleware
  use Cache
  alias OAuth2.{AccessToken, Client, Strategy}

  @strategy_map %{client_credentials: Strategy.ClientCredentials}

  def pipe(%Api{headers: %{} = headers} = a, %{oauth2: %{strategy: _} = cfg}) do
    cfg
    |> get_token()
    |> case do
      {:ok, %{token_type: token_type, access_token: access_token} = token} ->
        {:ok, token,
         %Api{a | headers: headers |> Map.put("authorization", "#{token_type} #{access_token}")}}

      {:error, reason} ->
        {:error, reason}
    end
  end

  @decorate cache({:expire_at, :expires_at})
  defp get_token(%{strategy: strategy} = cfg) do
    cfg
    |> Map.put(:strategy, Map.fetch!(@strategy_map, strategy))
    |> Map.to_list()
    |> Client.new()
    |> Client.get_token()
    |> case do
      {:ok, %Client{token: %AccessToken{} = token}} ->
        {:ok, Map.from_struct(token)}

      {:error, reason} ->
        {:error, reason}
    end
  rescue
    e ->
      {:error, use(Hf.ReportError, type: :oauth2_error, reason: e, stacktrace: __STACKTRACE__)}
  end
end
