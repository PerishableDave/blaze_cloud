defmodule BlazeCloud.Hash do
  def sha1(file_path) do
    hash = :crypto.hash_init(:sha)

    File.stream!(file_path, [], 2048)
    |> Enum.reduce(hash, fn (chunk, context) -> :crypto.hash_update(context, chunk) end)
    |> :crypto.hash_final
    |> Base.encode16
    |> String.downcase
  end
end
