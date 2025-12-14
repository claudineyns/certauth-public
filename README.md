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
  "ssl_reject_reason": [
    {
      "kind": "UNTRUSTED_CHAIN",
      "message": "Path does not chain with any of the trust anchors"
    }
  ],
  "trusted_by": "C=US, O=Let's Encrypt, CN=R3",
  "request_data": "eyJ0ZXN0IjogIm1lc3NhZ2UifQ==",
  "ssl_client": [
    {
      "subject_dn": "CN=client.example.com, O=My Organization",
      "issuer_dn": "C=US, O=Let's Encrypt, CN=R3",
      "serial": "04d8f2...",
      "valid_from": "1970-01-01T00:00:00Z",
      "valid_until": "1970-12-31T23:59:59Z"
      "status": "VALID_AND_NOT_EXPIRED",
      "fingerprint_sha256": "A1:B2:C3:D4...",
    }
  ]
}
```

### Attribute Definitions

| Field | Type | Description |
| :--- | :--- | :--- |
| `ssl` | Boolean | `true` if a client certificate was received, `false` otherwise. |
| `trusted_by` | String | The Distinguished Name (DN) of the CA that validated the chain. |
| `request_data` | String | The original request body payload encoded in **Base64**. Useful for verifying payload integrity. |
| `ssl_reject_reason` | Array | A list of reasons the certificate chain was rejected. Empty `[]` if valid. |
| `ssl_client` | Array | A list of objects detailing the certificate chain received. See [Client Certificate Object](#client-certificate-object-ssl_client-items) |

### Client Certificate Object (`ssl_client` items)

- `subject_dn`: The Distinguished Name of the certificate.
- `issuer_dn`: The Distinguished Name of the certificate issuer.
- `serial`: The certificate serial number in hexadecimal format.
- `valid_from`: Validity start time.
- `valid_until`: Validity expiration time.
- `fingerprint_sha256`: Certificate thumbprint.
- `status`: Certificate validity status.

### 🛠 Usage Examples (cURL)

You can test the endpoint using standard command-line tools like curl.

#### 1. Test without a certificate

This should return 401 Unauthorized.

```shell
curl -v https://mtls.certauth.dev
```

#### 2. Test with a client certificate (PEM + Key)

If the certificate is valid and trusted by the service, this returns 200 OK.

```shell
curl -v --cert client-cert.pem --key client-key.pem https://mtls.certauth.dev
```

#### 3. Test with a P12/PFX file

You can also use a PKCS#12 container.

```shell
curl -v --cert-type P12 --cert client-bundle.p12:password https://mtls.certauth.dev
```

## 🔐 Trusted CAs & Roots

This service validates client certificates against the **standard Mozilla CA Certificate Store** (commonly used by Linux distributions and browsers).

- **Public CAs:** Certificates issued by recognized public CAs (e.g., DigiCert, Let's Encrypt, GlobalSign) are accepted.
- **Self-Signed / Private CAs:** Currently, self-signed certificates or private corporate roots are **not trusted** and will result in a `403 Forbidden` response.

## 📡 Protocol Support

To ensure modern security standards, the service supports:
- **TLS 1.3** (Recommended)
- **TLS 1.2**
- **TLS 1.1**
- **TLS 1.0**

Legacy protocols (TLS 1.0, 1.1) if used, will produce an HTTP status `403 Forbidden`.

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
