# mTLS Client Certificate Validator

A simple, public utility service designed to test, debug, and validate Mutual TLS (mTLS) client authentication.

The service is available at: **https://mtls.certauth.dev**

## 🚀 How it Works

This tool inspects the client certificate provided in the TLS handshake and returns a JSON summary regarding the validation status. The HTTP status code indicates the result of the handshake verification:

| Status Code | Description |
| :--- | :--- |
| **`200 OK`** | The client certificate was provided and the chain is **valid** (trusted by the server). |
| **`401 Unauthorized`** | No client certificate was provided in the request. |
| **`403 Forbidden`** | A client certificate was provided, but the chain is **invalid** or untrusted. |

## 📄 Response Format

In all scenarios, the endpoint returns a JSON object containing the validation details.

### Example Response

```json
{
  "ssl": true,
  "trusted-by": "C=US, O=Let's Encrypt, CN=R3",
  "ssl-client": [
    {
      "subjectDN": "CN=client.example.com, O=My Organization",
      "issuerDN": "C=US, O=Let's Encrypt, CN=R3",
      "serial": "04d8f2...",
      "notBefore": 1698765432000,
      "notBeforeDateTime": "Tue, 31 Oct 2023 15:17:12 GMT",
      "notAfter": 1706541432000,
      "notAfterDateTime": "Mon, 29 Jan 2024 15:17:12 GMT"
    }
  ]
}
```

### Attribute Definitions

| Field | Type | Description |
| :---  | :--- | :--- |
|  ssl  | Boolean | `true` if a client certificate was received, `false` otherwise. |
| trusted-by | String | The Distinguished Name (DN) of the CA that validated the chain. |
| ssl-client | Array | A list of objects detailing the certificate chain received. See [Client Certificate Object](#client-certificate-object-ssl-client-items) |

### Client Certificate Object (`ssl-client` items)

- `subjectDN`: The Distinguished Name of the certificate.
- `issuerDN`: The Distinguished Name of the certificate issuer.
- `serial`: The certificate serial number in hexadecimal format.
- `notBefore`: Validity start time (Linux milliseconds).
- `notBeforeDateTime`: Validity start time (RFC 1123 format).
- `notAfter`: Validity expiration time (Linux milliseconds).
- `notAfterDateTime`: Validity expiration time (RFC 1123 format).

### 🛠 Usage Examples (cURL)

You can test the endpoint using standard command-line tools like curl.

#### 1. Test without a certificate

This should return 401 Unauthorized.

```shell
curl -v https://mtls.certauth.dev
```

### 2. Test with a client certificate (PEM + Key)

If the certificate is valid and trusted by the service, this returns 200 OK.

```shell
curl -v -cert client-cert.pem --key client-key.pem https://mtls.certauth.dev
```

### 3. Test with a P12/PFX file

You can also use a PKCS#12 container.

```shell
curl -v --cert-type P12 --cert client-bundle.p12:password https://mtls.certauth.dev
```

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
