defmodule BlazeCloud.Auth do
  @json_fields %{
    "accountId" => :account_id,
    "apiUrl" => :api_url,
    "authorizationToken" => :token,
    "downloadUrl" => :download_url}

  @type t :: %__MODULE__{account_id: String.t,
                         api_url: String.t,
                         token: String.t,
                         download_url: String.t}

  defstruct account_id: "",
            api_url: "",
            token: "",
            download_url: ""

  def from_json(json) do
    map = json
    |> Map.take(Map.keys(@json_fields))
    |> Enum.map(fn ({k, v}) -> {@json_fields[k], v} end)
    struct(__MODULE__, map)
  end
end
