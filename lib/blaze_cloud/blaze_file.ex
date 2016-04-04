defmodule BlazeCloud.BlazeFile do
  @json_fields %{
    "fileId" => :file_id,
    "fileName" => :file_name,
    "accountId" => :account_id,
    "contentSha1" => :sha,
    "bucketId" => :bucket_id,
    "contentLength" => :content_length,
    "contentType" => :content_type,
    "file_info" => :file_info,
    "action" => :action}

  @type t :: %__MODULE__{file_id: String.t,
                         file_name: String.t,
                         account_id: String.t,
                         sha: String.t,
                         bucket_id: String.t,
                         content_length: integer,
                         content_type: String.t,
                         file_info: map,
                         action: String.t}

  defstruct file_id: "",
            file_name: "",
            account_id: "",
            sha: "",
            bucket_id: "",
            content_length: 0,
            content_type: "",
            file_info: %{},
            action: ""

  def from_json(json) do
    map = json
    |> Map.take(Map.keys(@json_fields))
    |> Enum.map(fn ({k, v}) -> {@json_fields[k], v} end)
    struct(__MODULE__, map)
  end
end
