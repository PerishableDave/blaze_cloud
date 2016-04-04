defmodule BlazeCloud.RequestTest do
  use ExUnit.Case, async: false

  import Mock

  alias BlazeCloud.Request
  alias BlazeCloud.Auth
  alias HTTPoison.Response

  @account_id "some_account"
  @application_key "abcdef"
  @encoded_auth "Basic c29tZV9hY2NvdW50OmFiY2RlZg=="
  @token "hello"
  @api_url "https://someurl"
  @download_url "https://download"

  @auth %Auth{
    account_id: @account_id,
    api_url: @api_url,
    token: @token,
    download_url: @download_url
  }

  @authorize_account_url "https://api.backblaze.com/b2api/v1/b2_authorize_account"
  @authorize_json "{\"accountId\":\"some_account\",\"apiUrl\":\"https://someurl\",\"authorizationToken\":\"hello\",\"downloadUrl\":\"https://download\"}"
  test "authorize account returns a BlazeCloud.Auth on valid creds" do
    with_mock HTTPoison, [get: fn (url, headers) ->
      assert url == @authorize_account_url, "Invalid authorization endpoint."
      assert_header headers, "Authorization", @encoded_auth
      build_result(@authorize_json)
    end] do

      {:ok, auth} = Request.authorize_account(@account_id, @application_key)

      assert auth.account_id == @account_id
      assert auth.api_url == @api_url
      assert auth.token == @token
      assert auth.download_url == @download_url
    end
  end

  @create_bucket_name "some_bucket"
  @create_bucket_json "{\"bucketId\":\"4a48fe8875c6214145260818\",\"accountId\":\"010203040506\",\"bucketName\":\"#{@create_bucket_name}\",\"bucketType\":\"allPrivate\"}"
  test "create bucket returns the created bucket" do
    with_mock HTTPoison, [post: fn (url, body, headers) ->
      assert @api_url <> "/b2api/v1/b2_create_bucket"
      assert_header headers, "Authorization", @token
      build_result(@create_bucket_json)
    end] do
      {:ok, bucket} = Request.create_bucket(@auth, @create_bucket_name)

      assert bucket.bucket_id == "4a48fe8875c6214145260818"
      assert bucket.bucket_name == @create_bucket_name
    end
  end

  @delete_bucket_json "{\"bucketId\":\"1234\",\"accountId\":\"#{@account_id}\",\"bucketName\":\"any_name_you_pick\",\"bucketType\":\"allPrivate\"}"
  test "delete bucket returns the deleted bucket" do
    bucket_id = "1234"
    with_mock HTTPoison, [post: fn (url, body, headers) ->
        assert @api_url <> "b2api/v1/b2_delete_bucket"
        assert_header headers, "Authorization", @token
        parsed_body = Poison.decode!(body)
        assert parsed_body["accountId"] == @account_id
        assert parsed_body["bucketId"] == bucket_id
        build_result(@delete_bucket_json)
    end] do
      {:ok, bucket} = Request.delete_bucket(@auth, bucket_id)

      assert bucket.bucket_id == bucket_id
      assert bucket.account_id == @account_id
    end
  end

  @delete_file_version_json "{\"fileId\":\"1234\",\"fileName\":\"some_file\"}"
  test "delete file version returns deleted file" do
    file_id = "1234"
    file_name = "some_file"
    with_mock HTTPoison, [post: fn (url, body, headers) ->
      assert @api_url <> "b2api/v1/b2_delete_file_version"
      assert_header headers, "Authorization", @token
      parsed_body = Poison.decode!(body)
      assert parsed_body["fileName"] == file_name
      assert parsed_body["fileId"] == file_id
      build_result(@delete_file_version_json)
    end] do
      {:ok, json} = Request.delete_file_version(@auth, file_name, file_id)

      assert json["file_id"] == file_id
      assert json["file_name"] == file_name
    end
  end

  @list_buckets_json "{\"buckets\":[{\"bucketId\":\"4a48fe8875c6214145260818\",\"accountId\":\"30f20426f0b1\",\"bucketName\":\"Kitten Videos\",\"bucketType\":\"allPrivate\"},{\"bucketId\":\"5b232e8875c6214145260818\",\"accountId\":\"30f20426f0b1\",\"bucketName\":\"Puppy Videos\",\"bucketType\":\"allPublic\"},{\"bucketId\":\"87ba238875c6214145260818\",\"accountId\":\"30f20426f0b1\",\"bucketName\":\"Vacation Pictures\",\"bucketType\":\"allPrivate\"}]}"
  test "list buckets returns a lit of buckets" do
    with_mock HTTPoison, [get: fn (url, headers) ->
      assert url == @api_url <> "/b2api/v1/b2_list_buckets?accountId=" <> @account_id
      assert_header headers, "Authorization", @token
      build_result(@list_buckets_json)
    end] do

      {:ok, buckets} = Request.list_buckets(@auth)
      assert length(buckets) == 3
    end
  end

  @list_file_bucket_id "1234"
  @list_file_names_json "{\"files\":[{\"action\":\"upload\",\"fileId\":\"4_z27c88f1d182b150646ff0b16_f1004ba650fe24e6b_d20150809_m012853_c100_v0009990_t0000\",\"fileName\":\"files/hello.txt\",\"size\":6,\"uploadTimestamp\":1439083733000},{\"action\":\"upload\",\"fileId\":\"4_z27c88f1d182b150646ff0b16_f1004ba650fe24e6c_d20150809_m012854_c100_v0009990_t0000\",\"fileName\":\"files/world.txt\",\"size\":6,\"uploadTimestamp\":1439083734000}],\"nextFileName\":\"someName\"}"
  test "get file names returns files and a next token" do
    with_mock HTTPoison, [post: fn (url, body, headers) ->
      assert url == @api_url <> "/b2api/v1/b2_list_file_names"
      assert_header headers, "Authorization", @token
      build_result(@list_file_names_json)
    end] do
      {:ok, files, next_file} = Request.list_file_names(@auth, @list_file_bucket_id)
      assert length(files) == 2
      assert next_file == "someName"
    end
  end

  @get_upload_url_bucket "1234"
  @get_upload_json "{\"bucketId\":\"4a48fe8875c6214145260818\",\"uploadUrl\":\"https://pod-000-1005-03.backblaze.com/b2api/v1/b2_upload_file?cvt=c001_v0001005_t0027&bucket=4a48fe8875c6214145260818\",\"authorizationToken\":\"2_20151009170037_f504a0f39a0f4e657337e624_9754dde94359bd7b8f1445c8f4cc1a231a33f714_upld\"}"
  test "get upload url return an upload token" do
    with_mock HTTPoison, [post: fn (url, body, headers) ->
      assert url == @api_url <> "/b2api/v1/b2_get_upload_url"
      assert_header headers, "Authorization", @token
      build_result(@get_upload_json)
    end] do
      {:ok, upload_token} = Request.get_upload_url(@auth, @get_upload_url_bucket)
    end
  end

  # Helpers

  defp assert_header(headers, key, val) do
    header = Enum.find(headers, fn ({k, v}) -> k == key end)
    assert {key, val} == header
  end

  defp build_result(body, status \\ 200) do
    {:ok, %Response{status_code: status, body: body}}
  end
end
