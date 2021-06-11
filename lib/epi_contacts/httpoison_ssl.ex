defmodule EpiContacts.HTTPoisonSSL do
  @moduledoc """
  The following code for getting the SSL options for HTTPoison set up was originally from:
  https://elixirforum.com/t/using-client-certificates-from-a-string-with-httposion/8631/7
  using the response from kylethebaker that was posted on Sept. 1, 2017
  """

  def poison_http_options(private_key, public_cert, cert_password) do
    {_ans1_type, cert} = get_cert_der(public_cert)
    key = get_key_der(private_key, cert_password)

    [
      recv_timeout: 90_000,
      ssl: [
        cert: cert,
        key: key
      ]
    ]
  end

  defp decode_pem_bin(pem_bin) do
    pem_bin |> :public_key.pem_decode() |> hd()
  end

  defp decode_pem_entry(pem_entry) do
    :public_key.pem_entry_decode(pem_entry)
  end

  defp decode_pem_entry(pem_entry, password) do
    password = String.to_charlist(password)
    :public_key.pem_entry_decode(pem_entry, password)
  end

  defp encode_der(ans1_type, ans1_entity) do
    :public_key.der_encode(ans1_type, ans1_entity)
  end

  defp split_type_and_entry(ans1_entry) do
    ans1_type = elem(ans1_entry, 0)
    {ans1_type, ans1_entry}
  end

  defp get_cert_der(public_cert) do
    {cert_type, cert_entry} =
      public_cert
      |> decode_pem_bin()
      |> decode_pem_entry()
      |> split_type_and_entry()

    {cert_type, encode_der(cert_type, cert_entry)}
  end

  defp get_key_der(private_key, cert_password) do
    {key_type, key_entry} =
      private_key
      |> decode_pem_bin()
      |> decode_pem_entry(cert_password)
      |> split_type_and_entry()

    {key_type, encode_der(key_type, key_entry)}
  end
end
