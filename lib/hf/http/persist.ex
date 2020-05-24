defmodule Hf.Http.Persist do
  use Hf.Http.Common

  def fetch_proxy(%Api{options: %{proxy: {host, port}}}), do: "#{host}:#{port}"
  def fetch_proxy(_), do: nil

  def request_params(
        %Api{
          aid: aid,
          options: %{},
          state: :ok,
          input: %{parent_id: parent_id, job_id: job_id, attempt: attempt} = input,
          source: source,
          version: version,
          req: %Req{url: url, method: method}
        } = a,
        {:req, _}
      ) do
    %{
      state: input[:initial_state] || :init,
      input: input |> Map.drop([:job_id, :parent_id]),
      job_id: job_id,
      attempt: attempt,
      api_id: aid,
      proxy: fetch_proxy(a),
      parent_id: parent_id,
      method: method,
      source: source |> Tool.api_name(),
      url: url,
      version: version
    }
  end

  def request_params(%Api{state: :ok, resp: %Resp{body: body}}, {:resp, :before}) do
    %{state: :ok, raw: body}
  end

  def request_params(%Api{state: :ok, resp: %Resp{body: body}}, {:resp, :after}) do
    %{state: :ok, data: body}
  end

  def request_params(%Api{state: state, result: result}, {kind, _}) when kind != :req do
    %{state: state, result: result |> Util.inspect_binary()}
  end

  def build_payload(a, result \\ %{})

  def build_payload(
        %Api{resp: %Resp{headers: resp_headers, status_code: status_code}} = a,
        %{} = result
      ) do
    build_payload(
      %Api{a | resp: nil},
      result |> Map.merge(%{"status_code" => status_code, "resp_headers" => resp_headers})
    )
  end

  def build_payload(
        %Api{
          req: %Req{
            options: req_options,
            headers: req_headers,
            params: req_params,
            body: req_body
          }
        } = a,
        result
      ) do
    build_payload(
      %Api{a | req: nil},
      result
      |> Map.merge(%{
        "req_options" => req_options,
        "req_headers" => req_headers,
        "req_params" => req_params,
        "req_body" => req_body
      })
    )
  end

  def build_payload(_, result), do: result

  def merge_params(%{} = params, %Api{trace: trace, persist: %{} = persist} = a) do
    params |> Map.merge(persist) |> Map.merge(%{trace: trace, payload: build_payload(a)})
  end

  def build_req(%R{
        url: url,
        method: method,
        payload: %{
          "req_body" => req_body,
          "req_headers" => req_headers,
          "req_options" => req_options,
          "req_params" => req_params
        }
      }) do
    %Req{
      url: url,
      method: method,
      headers: req_headers,
      options: req_options,
      params: req_params,
      body: req_body
    }
  end

  ## TODO 如果空，需要重新来一遍 build_request
  def build_req(%R{}), do: nil

  def build_resp(%R{
        payload: %{"resp_headers" => headers, "status_code" => code},
        url: url,
        raw: raw
      }) do
    %Resp{body: raw, request_url: url, status_code: code, headers: headers}
  end

  def build_resp(%R{}), do: nil

  def load(
        %R{
          id: id,
          state: state,
          url: url,
          input: %{} = input,
          job_id: job_id,
          parent_id: parent_id,
          trace: trace,
          source: mod,
          version: version
        } = r
      ) do
    module = mod |> Tool.api_cast(version)
    input = Util.atomize_keys(input) |> Tool.merge_input()

    a = input |> module.struct()

    %Api{
      a
      | url: url,
        trace: trace,
        state: state,
        req: build_req(r),
        resp: build_resp(r),
        rid: id,
        input: %{input | job_id: job_id, parent_id: parent_id}
    }
  end

  def insert_or_update_request(%{} = params, %Api{rid: nil}) do
    {success, changes, r} = Domain.insert(R, params)
    {:persist_insert, success, changes, r}
  end

  def insert_or_update_request(%{} = params, %Api{rid: id}) do
    {success, changes, r} = Domain.update(R, params, id)
    {:persist_update, success, changes, r}
  end
end
