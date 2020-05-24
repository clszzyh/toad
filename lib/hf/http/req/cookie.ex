defmodule Hf.Http.Req.Cookie do
  use Hf.Http.Middleware

  def pipe(%Api{options: %{} = options} = a, %{cookie: %{} = cookies}) do
    opt = %{
      hackney: %{
        cookie: cookies |> Enum.map_join("; ", fn {k, v} -> "#{k}=#{v}" end) |> List.wrap()
      }
    }

    {:ok, opt, %Api{a | options: Tool.merge_map(options, opt)}}
  end
end
