defmodule BlazeCloud.UploadToken do
  @json_fields %{
    "bucketId" => :bucket_id,
    "uploadUrl" => :upload_url,
    "authorizationToken" => :auth_token}

  @type t :: %__MODULE__{bucket_id: String.t,
                         upload_url: String.t,
                         auth_token: String.t}

  defstruct bucket_id: "",
            upload_url: "",
            auth_token: ""

  def from_json(json) do
    map = json
    |> Map.take(Map.keys(@json_fields))
    |> Enum.map(fn ({k, v}) -> {@json_fields[k], v} end)
    struct(__MODULE__, map)
  end

end
