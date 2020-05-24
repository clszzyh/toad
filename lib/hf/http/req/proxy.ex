defmodule Hf.Http.Req.Proxy do
  use Hf.Http.Middleware

  @proxy_map %{
    local_http: {"127.0.0.1", 8123},
    local_socks: {:socks5, '127.0.0.1', 65_500}
  }

  @proxy_kinds @proxy_map |> Map.keys()

  def pipe(%Api{} = a, %{proxy: kind}) when kind in @proxy_kinds do
    merge_proxy(a, @proxy_map[kind])
  end

  # To use an HTTP tunnel add the option {proxy, ProxyUrl} where
  # ProxyUrl can be a simple url or an {Host, Port} tuple. If you need
  # to authenticate set the option {proxy_auth, {User, Password}}.
  # SOCKS5 proxy Hackney supports the connection via a socks5
  # proxy. To set a socks5 proxy, use the following settings: *
  # {proxy, {socks5, ProxyHost, ProxyPort}}: to set the host and port
  # of the proxy to connect.  * {socks5_user, Username}: to set the
  # user used to connect to the proxy * {socks5_pass, Password}: to
  # set the password used to connect to the proxy

  defp merge_proxy(%Api{options: options} = a, proxy) when is_tuple(proxy) do
    {:ok, proxy, %Api{a | options: Tool.merge_map(options, %{proxy: proxy})}}
  end
end
