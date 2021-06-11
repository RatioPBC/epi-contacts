defmodule EpiContacts.Encryption do
  @moduledoc """
  Wrapper around KCL for encryption.
  Encapsulates the usage of a secret key.
  """

  @nonce_size_bytes 24

  @doc """
  Encrypts a term with a generated nonce.
   
  Takes an pre-generated nonce, or generates one when necessary.

  ## Examples

      iex> encrypt("secret string")
      {"encrypted...", "nonce..."}

      iex> encrypt("secret string", "24 byte nonce")
      {"encrypted...", "encoded nonce..."}

      iex> encrypt(%{"some_key" => "secret string"})
      {"encrypted...", "nonce..."}
  """
  @spec encrypt(term()) :: {String.t(), String.t()}
  def encrypt(term, nonce \\ generate_nonce()) do
    encrypted_msg =
      term
      |> :erlang.term_to_binary()
      |> Kcl.secretbox(nonce, key())
      |> Base.encode64()

    {encrypted_msg, encode_nonce(nonce)}
  end

  @doc """
  Decrypts a string based on the given nonce.

  ### Examples

      iex> decrypt("encrypted...", "encoded nonce...")
      {:ok, "secret string"}

      iex> decrypt("encrypted...", "some other encoded nonce...")
      {:error, "failed to decrypt"}
  """
  @spec decrypt(String.t(), String.t()) :: {:ok, term()} | {:error, String.t()}
  def decrypt(encrypted_string, nonce_string) do
    {:ok, nonce} = decode_nonce(nonce_string)
    encrypted_msg = Base.decode64!(encrypted_string)

    case Kcl.secretunbox(encrypted_msg, nonce, key()) do
      :error -> {:error, "failed to decrypt"}
      msg -> {:ok, :erlang.binary_to_term(msg)}
    end
  end

  @spec generate_nonce() :: binary()
  def generate_nonce,
    do: :crypto.strong_rand_bytes(@nonce_size_bytes)

  @spec encode_nonce(binary()) :: String.t()
  def encode_nonce(nonce),
    do: Base.encode64(nonce)

  @spec decode_nonce(String.t()) :: {:ok, String.t()} | :error
  def decode_nonce(nonce_string),
    do: Base.decode64(nonce_string)

  defp key,
    do: Application.get_env(:epi_contacts, :encryption_key) |> Base.decode64!()
end
