# PKI Management System

A simple Public Key Infrastructure (PKI) management system implemented in Bash. This script allows you to create, manage, and revoke user certificates, as well as sign and verify files using these certificates.

## Table of Contents

- [Features](#features)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
    - [Initialize PKI](#initialize-pki)
    - [Create User](#create-user)
    - [Revoke User](#revoke-user)
    - [List Users](#list-users)
    - [Delete User](#delete-user)
    - [Sign File](#sign-file)
    - [Verify Signature](#verify-signature)
    - [Exit](#exit)
- [Troubleshooting](#troubleshooting)

## Features

- Initialize a PKI with a self-signed CA certificate.
- Create user certificates signed by the CA.
- Revoke user certificates and update the CRL (Certificate Revocation List).
- List existing users.
- Delete user certificates and related files.
- Sign files using a user's private key.
- Verify file signatures using the user's certificate.
- Comprehensive checks for certificate validity and revocation status.

## Prerequisites

- Bash shell.
- OpenSSL installed on the system.

## Installation

1. **Clone the repository**:

   ```bash
   git clone https://github.com/lumijiez/pki-bash.git
   cd pki-bash
   ```

2. **Ensure execute permissions**:

   ```bash
   chmod +x pki.sh
   ```

## Usage

Run the script to access the PKI management system:

```bash
./pki.sh
```

### Initialize PKI

- **Option**: 1. Initialize PKI
- **Description**: Sets up the PKI directory structure and generates a self-signed CA certificate.
- **Steps**:
    - Provide Country, State, Locality, Organization, Organizational Unit, Common Name, and Email Address when prompted.

### Create User

- **Option**: 2. Create User
- **Description**: Creates a new user with a private key and a certificate signed by the CA.
- **Steps**:
    - Enter a username.
    - Provide the necessary details (Country, State, etc.) for the certificate.

### Revoke User

- **Option**: 3. Revoke User
- **Description**: Revokes a user's certificate and updates the CRL.
- **Steps**:
    - Enter the username of the certificate to revoke.

### List Users

- **Option**: 4. List Users
- **Description**: Displays a list of existing users.
- **Steps**:
    - No input required.

### Delete User

- **Option**: 5. Delete User
- **Description**: Deletes a user's directory and certificate files.
- **Steps**:
    - Enter the username to delete.

### Sign File

- **Option**: 6. Sign File
- **Description**: Signs a file using a user's private key.
- **Steps**:
    - Enter the username.
    - Specify the file to sign.
    - The signature is saved as `<file>.sig`.

### Verify Signature

- **Option**: 7. Verify Signature
- **Description**: Verifies the signature of a file using the user's certificate.
- **Steps**:
    - Specify the file to verify.
    - Enter the username to verify against.
    - The script checks the certificate's validity and revocation status before verification.

### Exit

- **Option**: 8. Exit
- **Description**: Exits the PKI management system.

## Troubleshooting

- **Error: CRL file not found**:
    - Ensure that the CRL is generated after initializing the PKI or revoking a certificate.
- **Error: Certificate is invalid or revoked**:
    - The certificate may have been revoked or is not valid. Check the CRL and certificate files.