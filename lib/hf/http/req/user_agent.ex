defmodule Hf.Http.Req.UserAgent do
  use Hf.Http.Middleware

  def pipe(%Api{headers: %{"User-Agent" => _}}, %{random: true}) do
    {:ok, :exist!}
  end

  def pipe(%Api{headers: headers} = a, %{random: true}) do
    ua = random!()
    {:ok, ua, %Api{a | headers: headers |> Map.merge(%{"User-Agent" => ua})}}
  end

  defp random!, do: [:chrome, :firefox, :opera] |> Enum.random() |> generate()

  @chrome_versions [
    "65.0.3325.146",
    "64.0.3282.0",
    "41.0.2228.0",
    "40.0.2214.93",
    "37.0.2062.124"
  ]

  @firefox_versions [
    58.0,
    57.0,
    56.0,
    52.0,
    48.0,
    40.0,
    35.0
  ]

  @opera_versions [
    "2.7.62 Version/11.00",
    "2.2.15 Version/10.10",
    "2.9.168 Version/11.50",
    "2.2.15 Version/10.00",
    "2.8.131 Version/11.11",
    "2.5.24 Version/10.54"
  ]

  @os_versions [
    "Macintosh; Intel Mac OS X 10_10",
    "Windows NT 10.0",
    "Windows NT 5.1",
    "Windows NT 6.1; WOW64",
    "Windows NT 6.1; Win64; x64",
    "X11; Linux x86_64"
  ]

  defp os_v, do: @os_versions |> Enum.random()
  defp chrome_v, do: @chrome_versions |> Enum.random()
  defp firefox_v, do: @firefox_versions |> Enum.random()
  defp opera_v, do: @opera_versions |> Enum.random()

  defp generate(:chrome) do
    "Mozilla/5.0 (#{os_v()}) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/#{chrome_v()} Safari/537.36"
  end

  defp generate(:firefox) do
    v = firefox_v()
    "Mozilla/5.0 (#{os_v()}; rv:#{v}) Gecko/20100101 Firefox/#{v}"
  end

  defp generate(:opera) do
    "Opera/9.80 (#{os_v()}; U; en) Presto/#{opera_v()}"
  end
end
