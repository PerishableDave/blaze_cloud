defmodule BlazeCloud.Bucket do
  @json_fields %{
    "bucketId" => :bucket_id,
    "accountId" => :account_id,
    "bucketName" => :bucket_name,
    "bucketType" => :bucket_type}

  @type t :: %__MODULE__{bucket_id: String.t,
                         account_id: String.t,
                         bucket_name: String.t,
                         bucket_type: String.t}

  defstruct bucket_id: "",
            account_id: "",
            bucket_name: "",
            bucket_type: ""

  def from_json(json) do
    map = json
    |> Map.take(Map.keys(@json_fields))
    |> Enum.map(fn ({k, v}) -> {@json_fields[k], v} end)
    struct(__MODULE__, map)
  end
end
