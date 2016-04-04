defmodule BlazeCloud.Request do
  alias BlazeCloud.Auth
  alias BlazeCloud.Bucket
  alias BlazeCloud.UploadToken
  alias BlazeCloud.BlazeFile

  import BlazeCloud.Hash, only: [sha1: 1]

  @spec authorize_account(String.t, String.t) :: {:ok, Auth.t} | {:error, binary}
  def authorize_account(account_id, application_key) do
    url = "https://api.backblaze.com/b2api/v1/b2_authorize_account"
    basic_auth = Base.encode64 "#{account_id}:#{application_key}"
    auth_header = {"Authorization", "Basic #{basic_auth}"}

    with {:ok, response} <- HTTPoison.get(url, [auth_header]),
         {:ok, json} <- parse_response(response),
         do: {:ok, Auth.from_json(json)}
  end

  def cancel_large_file(auth, file_id) do

  end

  def create_bucket(auth, bucket_name, bucket_type \\ :private) do
    type = create_bucket_type(bucket_type)
    url = endpoint_url(auth, "b2_create_bucket")
    headers = put_header_token([], auth)
    body = Poison.encode!(%{
      "accountId" => auth.account_id,
      "bucketName" => bucket_name,
      "bucketType" => type})

    with {:ok, response} <- HTTPoison.post(url, body, headers),
         {:ok, json} <- parse_response(response),
         do: {:ok, Bucket.from_json(json)}
  end

  defp create_bucket_type(:private), do: "allPrivate"
  defp create_bucket_type(:public), do: "allPublic"

  def delete_bucket(auth, bucket_id) do
    url = endpoint_url auth, "b2_delete_bucket"
    headers = put_header_token [], auth
    body = Poison.encode!(%{
      "accountId" => auth.account_id,
      "bucketId" => bucket_id})

    with {:ok, response} <- HTTPoison.post(url, body, headers),
         {:ok, json} <- parse_response(response),
         do: {:ok, Bucket.from_json(json)}
  end

  def delete_file_version(auth, file_name, file_id) do
    url = endpoint_url auth, "b2_delete_file_version"
    headers = put_header_token [], auth
    body = Poison.encode!(%{
      "fileName" => file_name,
      "fileId" => file_id})

    with {:ok, response} <- HTTPoison.post(url, body, headers),
         {:ok, json} <- parse_response(response),
         do: {:ok, json}
  end

  def download_file(auth, file_id, range \\ []) do

  end

  def download_file_named(auth, filename, range \\ []) do

  end

  def finish_large_file() do

  end

  def get_file_info() do

  end

  @spec get_upload_url(Auth.t, String.t) :: {:ok, UploadToken.t} | {:error, String.t}
  def get_upload_url(auth, bucket_id) do
    url = endpoint_url(auth, "b2_get_upload_url")
    body = Poison.encode!(%{"bucketId" => bucket_id})
    headers = put_header_token([], auth)

    with {:ok, response} <- HTTPoison.post(url, body, headers),
         {:ok, json} <- parse_response(response),
         do: {:ok, UploadToken.from_json(json)}
  end

  def hide_file() do

  end

  @spec list_buckets(Auth.t) :: {:ok, [Bucket.t]} | {:error, binary}
  def list_buckets(auth) do
    url = endpoint_url(auth, "b2_list_buckets", accountId: auth.account_id)
    headers = put_header_token([], auth)

    with {:ok, response} <- HTTPoison.get(url, headers),
         {:ok, json} <- parse_response(response),
         {:ok, buckets_json} <- Map.fetch(json, "buckets"),
         do: {:ok, Enum.map(buckets_json, &(Bucket.from_json(&1)))}

  end

  @spec list_file_names(Auth.t, String.t, String.t | nil) :: {:ok, [BlazeFile.t], String.t} | {:error, binary}
  def list_file_names(auth, bucket_id, next_file \\ nil) do
    url = endpoint_url(auth, "b2_list_file_names")
    params = %{bucketId: bucket_id}
    body = Poison.encode!(params)
    headers = put_header_token([], auth)

    with {:ok, response} <- HTTPoison.post(url, body, headers),
         {:ok, json} <- parse_response(response),
         files <- Enum.map(json["files"], &(BlazeFile.from_json(&1))),
         do: {:ok, files, json["nextFileName"]}
  end

  def list_file_versions() do

  end

  def list_parts() do

  end

  def list_unfinished_large_files() do

  end

  def start_large_file() do

  end

  def update_bucket() do

  end

  @spec upload_file(UploadToken.t, String.t, Path.t, String.t) :: {:ok, File.t} | {:error, String.t}
  def upload_file(upload_token, file_name, file_path, content_type \\ "b2/x-auto") do
    %File.Stat{size: file_size} = File.lstat!(file_path)
    hash = sha1(file_path)

    headers = [
      {"X-Bz-File-Name", URI.encode(file_name)},
      {"Content-Type", content_type},
      {"Content-Length", file_size},
      {"X-Bz-Content-Sha1", hash},
      {"Authorization", upload_token.auth_token}]

    with {:ok, response} <- HTTPoison.post(upload_token.upload_url, {:file, file_path}, headers),
         {:ok, json} <- parse_response(response),
         do: BlazeFile.from_json(json)
  end

  def upload_part() do

  end

  # Utility

  defp put_header_token(headers, auth) do
    headers ++ [{"Authorization", auth.token}]
  end

  defp endpoint_url(auth, operation, params \\ []) do
    url = auth.api_url <> "/b2api/v1/" <> operation
    case params do
      [] -> url
      params -> url <> "?" <> URI.encode_query(params)
    end
  end

  defp parse_response(response) do
    case response do
      %HTTPoison.Response{status_code: 200, body: body} ->
        Poison.decode(body)
      %HTTPoison.Response{status_code: status_code} ->
        {:error, "Returned with status code: #{status_code}"}
    end
  end
end
