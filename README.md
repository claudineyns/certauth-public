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
| **`406 Not Acceptable`** | The client request did not include `application/json` or `*/*`in the `Accept` header. |

## ⚡ Quick Start (Automated Script)

Don't want to manually generate certificates? We provide a ready-to-use bash script that generates a temporary self-signed certificate and tests the endpoint automatically.

```bash
# Download and run the test script
curl -O https://raw.githubusercontent.com/claudineyns/certauth-public/main/test-validator.sh
chmod +x test-validator.sh
./test-validator.sh
```
*Requirements: `curl` and `openssl`.*

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
  ],
  "trusted_by": {
    "subject_dn": "C=US, O=Let's Encrypt, CN=R3",
    "issuer_dn": "C=US, O=Let's Encrypt, CN=R3",
    "serial": "04d8f2...",
    "valid_from": "1970-01-01T00:00:00Z",
    "valid_until": "1970-12-31T23:59:59Z"
    "fingerprint_sha256": "A1:B2:C3:D4...",
  },
  "request_data": "eyJ0ZXN0IjogIm1lc3NhZ2UifQ=="
}
```

### Attribute Definitions

| Field | Type | Description |
| :--- | :--- | :--- |
| `ssl` | Boolean | `true` if a client certificate was received, `false` otherwise. |
| `trusted_by` | Object | Detailed information about trusted anchor that validated the chain. |
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

```shell
# This should return 401 Unauthorized
curl -v https://mtls.certauth.dev
```

#### 2. Test with a client certificate (PEM + Key)

If the certificate is valid and trusted by the service, this returns `200 OK`. Otherwise, returns `403 Forbidden`.

```shell
curl -v --cert client-cert.pem --key client-key.pem https://mtls.certauth.dev
```

#### 3. Test with a P12/PFX file

You can also use a PKCS#12 container.

```shell
curl -v --cert-type P12 --cert client-bundle.p12:password https://mtls.certauth.dev
```

#### 4. Test with Invalid Accept Header

The service strictly produces JSON. If your client does not request such in header `Accept`, the service will reject the request.

```shell
# This will return 406 Not Acceptable
curl -v -H "Accept: application/xml" https://mtls.certauth.dev
```

## 🔐 Trusted CAs & Validation Logic

The service employs a **Dual Trust Mode** to support both public and development scenarios:

### 1. Public Trust Mode (Standard)
If the provided certificate chain ends with a root CA certificate that is **not** self-signed (or is a known public root), the service validates it against the **Mozilla CA Certificate Store**.
* **Success:** Chain is valid and rooted in a trusted public CA.
* **Failure:** Chain is broken, expired, or rooted in an unknown CA.

### 2. Self-Signed / Custom Trust Mode (Dev Friendly)
If the provided chain consists of a **single self-signed certificate** or the **last certificate in the chain is self-signed**, the service switches to "Custom Trust Mode".
* **Logic:** The service treats the self-signed certificate as the **Trust Anchor** for that specific request.
* **Validation:** It verifies that the chain is cryptographically valid relative to that self-signed root (signatures and dates).
* **Result:** Returns `200 OK` with `"ssl": true`, allowing you to debug self-signed chains without setting up a public PKI.

### ⛓️ Chain Order Validation
Strict RFC compliance is enforced regarding the order of certificates in the chain.
* The chain must be ordered: `[Client Cert] -> [Intermediate A] -> [Intermediate B] -> [Root/Anchor]`.
* If a certificate's **Issuer** does not match the **Subject** of the next certificate in the list, the request is rejected with `403 Forbidden` and a specific error message in `ssl-reject-reason`.

## 📡 Protocol Support

To ensure modern security standards, the service supports:
- **TLS 1.3** (Recommended)
- **TLS 1.2**

Legacy protocols (TLS 1.0, 1.1) is not allowed.

## ⚖️ Fair Use Policy

This API is provided as a free public utility.
- Please be mindful of resource usage.
- Heavy automated scanning or integration into high-frequency CI/CD pipelines is discouraged and may be subject to rate limiting.

## 🔒 Privacy & Security

We take security seriously. Please note the following regarding your usage of this service:

- **Stateless Operation:** This service is entirely stateless. We do not store, log, or cache any certificate data presented during the request. The validation is performed in memory, and the results are discarded immediately after the response is sent.
- **Private Keys:** Following standard mTLS protocol, **your private key is never transmitted to the server**. It remains securely on your client machine. The server only receives and validates your public certificate chain.
- **Usage:** This tool is intended for development, debugging, and testing purposes only.

## 📚 Useful Resources

Generating valid certificate chains for mTLS testing can be complex. If you want to learn more about certificate management or need a quick reference for OpenSSL commands, I highly recommend:

- **[OpenSSL Cheatsheet by GoLinuxCloud](https://www.golinuxcloud.com/openssl-cheatsheet/)**

This resource was instrumental in the learning process for this project and is an excellent guide for creating your own CA and client certificates.

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
