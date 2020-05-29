defmodule Hf.Http.Resp.CodeMsg do
  use Hf.Http.Middleware

  def pipe(%Api{state: :ok, resp: %Resp{body: %{"code" => code, "msg" => msg}}}, _)
      when code not in [0, "0"] do
    {:error, "#{code} #{msg}"}
  end

  def pipe(%Api{state: :ok, resp: %Resp{body: %{"code" => code, "message" => msg}}}, _)
      when code not in [0, "0"] do
    {:error, "#{code} #{msg}"}
  end

  def pipe(
        %Api{
          state: :ok,
          resp: %Resp{body: %{"code" => code, "msg" => msg, "result" => result}} = resp
        } = a,
        _
      )
      when code in [0, "0"] do
    {:ok, msg, %Api{a | resp: %Resp{resp | body: result}}}
  end

  def pipe(
        %Api{
          state: :ok,
          resp: %Resp{body: %{"code" => code, "message" => msg, "body" => result}} = resp
        } = a,
        _
      )
      when code in [0, "0"] do
    {:ok, msg, %Api{a | resp: %Resp{resp | body: result}}}
  end
end
