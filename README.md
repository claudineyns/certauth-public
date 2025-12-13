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
| :--- | :--- | :--- |
| `ssl` | Boolean | `true` if a client certificate was received, `false` otherwise. |
| `trusted-by` | String | The Distinguished Name (DN) of the CA that validated the chain. |
| `ssl-client` | Array | A list of objects detailing the certificate chain received. See [Client Certificate Object](#client-certificate-object-ssl-client-items) |

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
curl -v [https://mtls.certauth.dev](https://mtls.certauth.dev)
```

#### 2. Test with a client certificate (PEM + Key)

If the certificate is valid and trusted by the service, this returns 200 OK.

```shell
curl -v --cert client-cert.pem --key client-key.pem [https://mtls.certauth.dev](https://mtls.certauth.dev)
```

#### 3. Test with a P12/PFX file

You can also use a PKCS#12 container.

```shell
curl -v --cert-type P12 --cert client-bundle.p12:password [https://mtls.certauth.dev](https://mtls.certauth.dev)
```

## 🔐 Trusted CAs & Roots

This service validates client certificates against the **standard Mozilla CA Certificate Store** (commonly used by Linux distributions and browsers).

- **Public CAs:** Certificates issued by recognized public CAs (e.g., DigiCert, Let's Encrypt, GlobalSign) are accepted.
- **Self-Signed / Private CAs:** Currently, self-signed certificates or private corporate roots are **not trusted** and will result in a `403 Forbidden` response.

## 📡 Protocol Support

To ensure modern security standards, the service supports:
- **TLS 1.3** (Recommended)
- **TLS 1.2**

Legacy protocols (TLS 1.0, 1.1) and weak cipher suites are disabled.

## ⚖️ Fair Use Policy

This API is provided as a free public utility.
- Please be mindful of resource usage.
- Heavy automated scanning or integration into high-frequency CI/CD pipelines is discouraged and may be subject to rate limiting.

## 🔒 Privacy & Security

We take security seriously. Please note the following regarding your usage of this service:

- **Stateless Operation:** This service is entirely stateless. We do not store, log, or cache any certificate data presented during the request. The validation is performed in memory, and the results are discarded immediately after the response is sent.
- **Private Keys:** Following standard mTLS protocol, **your private key is never transmitted to the server**. It remains securely on your client machine. The server only receives and validates your public certificate chain.
- **Usage:** This tool is intended for development, debugging, and testing purposes only.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
