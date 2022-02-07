defmodule EpiContacts.EncryptionTest do
  use ExUnit.Case, async: true

  alias EpiContacts.Encryption

  describe "generate_nonce/0" do
    test "generates a binary with size 24" do
      assert 24 == Encryption.generate_nonce() |> byte_size
    end

    test "generates different values on subsequent calls" do
      nonce1 = Encryption.generate_nonce()
      nonce2 = Encryption.generate_nonce()

      refute nonce1 == nonce2
    end
  end

  describe "encode and decode nonce" do
    test "turns a nonce into a base64 encoded string and back" do
      nonce = Encryption.generate_nonce()

      encoded_nonce = Encryption.encode_nonce(nonce)
      assert encoded_nonce != nonce

      {:ok, decoded_nonce} = Encryption.decode_nonce(encoded_nonce)
      assert nonce == decoded_nonce
    end
  end

  describe "encrypt" do
    test "returns the base64-encoded encrypted string and a base64-encoded string representation of the nonce used" do
      secret_string = "very secret"

      {encrypted_string, nonce_string} = Encryption.encrypt(secret_string)

      assert 24 == nonce_string |> Base.decode64!() |> byte_size

      refute encrypted_string == secret_string
    end
  end

  describe "decrypt" do
    test "returns the original value if the same nonce is used for encryption and decryption" do
      secret_string = "very secret"

      {encrypted_string, nonce_string} = Encryption.encrypt(secret_string)
      {:ok, decrypted_string} = Encryption.decrypt(encrypted_string, nonce_string)

      assert decrypted_string == secret_string
    end

    test "does not return the original value if different nonces are used for encryption and decryption" do
      secret_string = "very secret"

      {encrypted_string, _nonce_string} = Encryption.encrypt(secret_string)
      other_nonce_string = Encryption.generate_nonce() |> Encryption.encode_nonce()

      assert {:error, _msg} = Encryption.decrypt(encrypted_string, other_nonce_string)
    end
  end

  test "encrypts and decrypts a map" do
    map = %{"a" => "an value", "b" => 1}

    {encrypted_map, nonce_string} = Encryption.encrypt(map)

    assert map != encrypted_map

    {:ok, decrypted_map} = Encryption.decrypt(encrypted_map, nonce_string)

    assert map == decrypted_map
  end
end
