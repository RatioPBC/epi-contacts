defmodule EpiContacts.HTTPoisonSSLTest do
  # Originally from: https://elixirforum.com/t/using-client-certificates-from-a-string-with-httposion/8631/7
  # Using the response from kylethebaker on Sept. 1, 2017

  alias EpiContacts.HTTPoisonMock
  alias EpiContacts.HTTPoisonSSL

  use ExUnit.Case, async: false

  import Mox

  setup :set_mox_global
  setup :verify_on_exit!

  @private_key """
               -----BEGIN RSA PRIVATE KEY-----
               Proc-Type: 4,ENCRYPTED
               DEK-Info: AES-128-CBC,E9BF6F551AB6C6C8E2ACB1FD9B7BF860

               JkeMooohdh8OT0y2DuRIZqcotwUQmwkAYVy6LKSRQ/bpfZL1p1jQc60S7BE4e0AT
               QtjmxPi26VQjYiR13/v/PUfoP5bUwz3aEWbBARBCE++Fl92dB8jH1e+DOR3b9MZ/
               cWXI6Qi/TKCMnl9JG+mh4l+THBspTLKC3qj1RM0Fdg4Zh1NtxKmmY/zXgx+ss7oZ
               r8sAjLnuqT9mttjp+eC8ycgWIXySRsiuIE/r89ySny8rvLcOQXOc3f3SDLtpZhgM
               p1VYGYZaa0oKvuPHUu1rGKxd0rLrW0tFZ1S2G9DQGRTAD1NB8CrHlNQXChKHBbOB
               4nd2Bd2Awi4Ut9otrX8KMRaPe6lwJivOu+j8GaVyukZ+FGfHD5riWnWdaUny3Gfu
               B+plHs0DmXYfl35+Cm0ZvyorQXXrPGodhqAeWXEfWeaLqBqv8WafGcKaYng7TEbh
               MXzzZ5TxZG5jAzAutuCDXzV5ZXXe1CYgJEPKdlb7favK7UU9OziqX/Xj6fye8Sf/
               ybiUYdXJFWZVPvVqeFxwwURLIhf21Lg9J7LBt3wek9GrezTGou3JXMzr5/66ENTB
               UEPSWtZtKsLsfKWLrsf1I1WHSVbOMUhln/7t+7wOM4bb+Km3ZfqjE6RBxNCdcRQW
               u1Fxg1Bxs8O6nNpXT+YPAg7yA+gmYXdkoAinrwswKtQu+cOQhl0ZwaW9u7OTTsAC
               ZVWlp7KgpVwJ6yM5HfttdCt/RcWkU95NfhgGt3SVRNUkpk9gUoMsVyav5783Tg6t
               nfigUKKlOrDqMOUQJDP5bTDkWdWTLcmH+4AGEgGJVKuE0kF3uiU0qgU4IUH+L0oi
               1QQpdEWR+2zYdGmDJBWEyevWvoqxcCq+YTVbGxlqFjO5KImR5nmEDYz7M1/FyqXX
               Dp56X75HpoeL+zuDBl+evwKh5JiBDcvOSL7+st77gTaW1kAIrC31ItVOkuWKU259
               cXwq8SQ1Xdg8ihcxfUQmvS1BksRgVoh2G1YZK6mrIeKMG+yPnncxV3rBe65K24/U
               6oU9GNGenQx9dzvp2nhPtMzgDOnwhdvMOXnQ5iMyjWPRtEtLEFzz+dEluZwdYibv
               ZZnJvCGO3ug83guFvuQshuHy2DyipdyazKhmNR21yxUXTuV9ezzGQIjgf0viONEQ
               pIb65h16ynx4yWVNyfdTgiKy1TK8ReYzIYDHuP3k6yt/soGHNEwb32yRbzIeq1wq
               S8iSJNuij809rxgDJlvXiVPTu6a93itbUoD1W+kC+dI5wvA9uAKTSOZDqII5K2bw
               BidYt2NxIfnmzBhAR7y75TAL93UNInEw0efAenQ7I2UqMZOW2NXCrxoToYkbWXQz
               AX/VvejcghINZAArPyYmSrjqi+6YhJu9BJs1X77rJbmveVvL2aH/r9XsXGxEqVGB
               XgpYR7xwN9AmTkt8cetUUHcJ1XBU1OC9Pc4FUS0qIQ1UVjxWWP5yUiYmx/z6g5q3
               jPC8lIPjtdZYxC5tewMM5arl3eh1H9URgq5Eczg5FxpybmAYyVrtOBiVXOdD40Bf
               DUotXu7FD/w3UEeq35dVjvOIlUq38z3Ll4PjeUrcTLAsLcUfViTHrh0Aq+Cyxg13
               -----END RSA PRIVATE KEY-----
               """
               |> String.trim()

  @public_cert """
               -----BEGIN CERTIFICATE-----
               MIIDBjCCAe4CCQDDhq+iQYSezjANBgkqhkiG9w0BAQsFADBFMQswCQYDVQQGEwJB
               VTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwYSW50ZXJuZXQgV2lkZ2l0
               cyBQdHkgTHRkMB4XDTE3MDkxNDIxMjM0OVoXDTE4MDkxNDIxMjM0OVowRTELMAkG
               A1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAfBgNVBAoMGEludGVybmV0
               IFdpZGdpdHMgUHR5IEx0ZDCCASIwDQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEB
               AL2y30DlnBpy0XACIqgdj1ZroIf1kl5tIuM4nOxL+piigvU/0nSCZl1tj+kvtHyC
               rOkwg7SoPn9xoDbikvDX8zr2OwOGI01zXn8zUp1jukLzPr0hcgkjxb+fTgSmTNxI
               fiZ+WYUnCS1TcKmgL50uKACXSTWt9ZZaDlZZ0Ta8gPh7LFyD2ie5rxyQyESTNykv
               LirUx02nuCuF2VaF7lPGz+cSxZHKy+OgNvHtHWDUCD3e5wIbYStVdnpetFo5VsiA
               v+/r5fbBCjanYoJTXecg5swVhxeuLi3LpjE4syOTJbpu2xtTA0KjMZhXcaMbZ6kn
               SkpaFIgHFHq/WYwDYDj14B0CAwEAATANBgkqhkiG9w0BAQsFAAOCAQEAN8IWdVua
               /8ag/7EUxwTWAJn4qYQHXo9tmWJxuYy1Lf5PVcNTqVcEOQG2ZJBi7F6ADHgbLc2N
               e5fsLca2VYpQ6LvEi9sHun06t7KI6PPB3/EzesTMJzAr5aWK9NdcqjTEtjshZNnt
               TIZwFrzX7XSZzpBijS0tEItYbJuraYC2LWuFhJtzTiStK4NrzfyFJVG0oQ1V3SU4
               n9EAFBu23FS52qfxrTauTCNYL43V+ha2gvm70VJAQIVpQs4Z3MgSyKGYr+LAIuKB
               dtY/lEgcUYhXY5Dzqt7DotJLRM1i/dWUrxLjLw0oyMi4EyQn2j4GmN4nlr/yBPdM
               EVCBwVsZ06HKtA==
               -----END CERTIFICATE-----
               """
               |> String.trim()

  @cert_password "password"

  test "poison_http_options/3" do
    options = HTTPoisonSSL.poison_http_options(@private_key, @public_cert, @cert_password)

    assert Keyword.get(options, :recv_timeout) == 90_000

    ssl_options = Keyword.get(options, :ssl)
    assert Keyword.get(ssl_options, :cert)
    assert Keyword.get(ssl_options, :key)
  end

  # When developing, toggle @use_mox to false if you want to hit a real remote server using the HTTPoisonSSL options.
  # This can be quite useful to verify that it is actually working in real life, not just in mocked out mode.
  # Toggle it to true for default usage so that the test suite is not hitting an external server.
  @use_mox true

  describe "talking to a test server with HTTPoison and SSL" do
    setup do
      httpoison =
        if @use_mox do
          expect(HTTPoisonMock, :get, fn _url, _headers, _options ->
            {:ok, %HTTPoison.Response{status_code: 200, body: body(), request_url: "https://httpbin.org/get?foo=bar"}}
          end)

          HTTPoisonMock
        else
          HTTPoison
        end

      [httpoison: httpoison]
    end

    test "get ssl working with HTTPoison", %{httpoison: httpoison} do
      {:ok, response} =
        httpoison.get(
          "https://httpbin.org/get?foo=bar",
          %{},
          HTTPoisonSSL.poison_http_options(@private_key, @public_cert, @cert_password)
        )

      assert response.status_code == 200
      assert response.request_url == "https://httpbin.org/get?foo=bar"
    end
  end

  def body do
    # This was captured from doing the real GET against the remote server.
    """
    {
        "args": {
          "foo": "bar"
        },
        "headers": {
          "Host": "httpbin.org",
          "User-Agent": "hackney/1.16.0",
          "X-Amzn-Trace-Id": "Root=1-5f1721fe-a8aa0dd2f43e243ae93a619e"
        },
        "origin": "167.172.222.53",
        "url": "https://httpbin.org/get?foo=bar"
      }
    """
  end
end
