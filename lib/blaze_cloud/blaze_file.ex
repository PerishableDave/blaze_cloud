defmodule BlazeCloud.BlazeFile do
  @json_fields %{
    "accountId" => :account_id,
    "bucketId" => :bucket_id,
    "contentLength" => :content_length,
    "contentSha1" => :sha,
    "contentType" => :content_type,
    "fileId" => :file_id,
    "fileInfo" => :file_info,
    "fileName" => :file_name
  }

  @type t :: %__MODULE__{account_id: String.t,
                         bucket_id: String.t,
                         content_length: pos_integer,
                         sha: String.t,
                         content_type: String.t,
                         file_id: String.t,
                         file_info: String.t,
                         file_name: String.t}


  defstruct account_id: "",
            bucket_id: "",
            content_length: 0,
            sha: "",
            content_type: "",
            file_id: "",
            file_info: %{},
            file_name: ""

  def from_json(json) do
    map = json
    |> Map.take(Map.keys(@json_fields))
    |> Enum.map(fn ({k, v}) -> {@json_fields[k], v} end)
    struct(__MODULE__, map)
  end
end
