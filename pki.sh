#!/bin/bash

BASE_DIR="pki"
CA_DIR="$BASE_DIR/ca"
USERS_DIR="$BASE_DIR/users"
CERTS_DIR="$BASE_DIR/certs"
CRL_DIR="$BASE_DIR/crl"

get_input() {
    read -p "$1: " INPUT
    echo "$INPUT"
}

initialize_pki() {
    echo "Initializing PKI..."
    mkdir -p "$CA_DIR" "$USERS_DIR" "$CERTS_DIR" "$CRL_DIR"
    chmod -R 777 "$BASE_DIR"

    echo "Generating CA private key (4096 bits)..."
    openssl genrsa -out "$CA_DIR/ca.key" 4096

    echo "Creating self-signed CA certificate (10 years)..."
    C="$(get_input 'Enter Country (2 letters)')"
    ST="$(get_input 'Enter State')"
    L="$(get_input 'Enter Locality')"
    O="$(get_input 'Enter Organization')"
    OU="$(get_input 'Enter Organizational Unit')"
    CN="$(get_input 'Enter Common Name')"
    EMAIL="$(get_input 'Enter Email Address')"

    openssl req -new -x509 -days 3650 -key "$CA_DIR/ca.key" \
        -out "$CA_DIR/ca.crt" \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN/emailAddress=$EMAIL"

    touch "$CA_DIR/index.txt"
    echo 1000 > "$CA_DIR/serial"
    echo 1000 > "$CA_DIR/crlnumber"


    echo "Generating initial CRL..."
    openssl ca -gencrl -out "$CRL_DIR/ca.crl" -config <(cat <<-EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
default_md = sha256
certs = $CERTS_DIR
new_certs_dir = $CERTS_DIR
database = $CA_DIR/index.txt
serial = $CA_DIR/serial
private_key = $CA_DIR/ca.key
certificate = $CA_DIR/ca.crt
crl_dir = $CRL_DIR
crlnumber = $CA_DIR/crlnumber
default_crl_days = 30
unique_subject = no
policy = policy_any

[ policy_any ]
countryName = optional
stateOrProvinceName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional
EOF
    )
    echo "Initial CRL generated successfully."
    echo "PKI initialized successfully."

}

create_user() {
    USER_NAME="$(get_input 'Enter username')"
    USER_DIR="$USERS_DIR/$USER_NAME"

    if [ -d "$USER_DIR" ]; then
        echo "User $USER_NAME already exists."
        return
    fi

    mkdir -p "$USER_DIR"
    chmod -R 777 "$USER_DIR"

    echo "Generating private key for $USER_NAME (2048 bits)..."
    openssl genrsa -out "$USER_DIR/$USER_NAME.key" 2048

    echo "Creating certificate signing request for $USER_NAME..."
    C="$(get_input 'Enter Country (2 letters)')"
    ST="$(get_input 'Enter State')"
    L="$(get_input 'Enter Locality')"
    O="$(get_input 'Enter Organization')"
    OU="$(get_input 'Enter Organizational Unit')"
    CN="$(get_input 'Enter Common Name')"
    EMAIL="$(get_input 'Enter Email Address')"

    openssl req -new -key "$USER_DIR/$USER_NAME.key" \
        -out "$USER_DIR/$USER_NAME.csr" \
        -subj "/C=$C/ST=$ST/L=$L/O=$O/OU=$OU/CN=$CN/emailAddress=$EMAIL"

    echo "Signing user certificate with CA..."
    openssl ca -batch -days 365 -in "$USER_DIR/$USER_NAME.csr" \
        -out "$USER_DIR/$USER_NAME.crt" -cert "$CA_DIR/ca.crt" -keyfile "$CA_DIR/ca.key" \
        -config <(cat <<-EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
default_md = sha256
certs = $CERTS_DIR
new_certs_dir = $CERTS_DIR
database = $CA_DIR/index.txt
serial = $CA_DIR/serial
private_key = $CA_DIR/ca.key
certificate = $CA_DIR/ca.crt
crl_dir = $CRL_DIR
crlnumber = $CA_DIR/crlnumber
default_crl_days = 30
unique_subject = no
policy = policy_any

[ policy_any ]
countryName = optional
stateOrProvinceName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional
EOF
)

    cp "$USER_DIR/$USER_NAME.crt" "$CERTS_DIR/$USER_NAME.crt"
    echo "User $USER_NAME created successfully."
}

revoke_user() {
    USER_NAME="$(get_input 'Enter username to revoke')"
    USER_DIR="$USERS_DIR/$USER_NAME"

    if [ ! -f "$USER_DIR/$USER_NAME.crt" ]; then
        echo "Certificate for $USER_NAME does not exist."
        return
    fi

    echo "Revoking certificate for $USER_NAME..."
    openssl ca -revoke "$USER_DIR/$USER_NAME.crt" -keyfile "$CA_DIR/ca.key" -cert "$CA_DIR/ca.crt" \
    -config <(cat <<-EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
default_md = sha256
certs = $CERTS_DIR
new_certs_dir = $CERTS_DIR
database = $CA_DIR/index.txt
serial = $CA_DIR/serial
private_key = $CA_DIR/ca.key
certificate = $CA_DIR/ca.crt
crl_dir = $CRL_DIR
crlnumber = $CA_DIR/crlnumber
default_crl_days = 30
unique_subject = no
policy = policy_any

[ policy_any ]
countryName = optional
stateOrProvinceName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional
EOF
)

    echo "Generating CRL..."
    openssl ca -gencrl -out "$CRL_DIR/ca.crl" -config <(cat <<-EOF
[ ca ]
default_ca = CA_default

[ CA_default ]
default_md = sha256
certs = $CERTS_DIR
new_certs_dir = $CERTS_DIR
database = $CA_DIR/index.txt
serial = $CA_DIR/serial
private_key = $CA_DIR/ca.key
certificate = $CA_DIR/ca.crt
crl_dir = $CRL_DIR
crlnumber = $CA_DIR/crlnumber
default_crl_days = 30
unique_subject = no
policy = policy_any

[ policy_any ]
countryName = optional
stateOrProvinceName = optional
organizationName = optional
organizationalUnitName = optional
commonName = supplied
emailAddress = optional
EOF
)

    echo "Certificate for $USER_NAME revoked."
}

list_users() {
    echo "Existing users:"
    ls "$USERS_DIR"
}

delete_user() {
    USER_NAME="$(get_input 'Enter username to delete')"
    USER_DIR="$USERS_DIR/$USER_NAME"

    if [ ! -d "$USER_DIR" ]; then
        echo "User $USER_NAME does not exist."
        return
    fi

    rm -rf "$USER_DIR"
    rm -f "$CERTS_DIR/$USER_NAME.crt"
    echo "User $USER_NAME deleted successfully."
}

sign_file() {
    USER_NAME="$(get_input 'Enter username to sign with')"
    USER_DIR="$USERS_DIR/$USER_NAME"
    FILE="$(get_input 'Enter file to sign')"
    SIGNATURE="$FILE.sig"

    if [ ! -f "$USER_DIR/$USER_NAME.key" ]; then
        echo "Private key for $USER_NAME not found."
        return
    fi


    if ! openssl verify -CAfile "$CA_DIR/ca.crt" -crl_check -CRLfile "$CRL_DIR/ca.crl" "$USER_DIR/$USER_NAME.crt"; then
        echo "Cannot sign. Certificate for $USER_NAME is invalid or revoked."
        return
    fi
    openssl dgst -sha256 -sign "$USER_DIR/$USER_NAME.key" -out "$SIGNATURE" "$FILE"

    echo "File signed. Signature saved as $SIGNATURE."
}

verify_signature() {
    FILE="$(get_input 'Enter file to verify')"
    SIGNATURE="$FILE.sig"
    USER_NAME="$(get_input 'Enter username to verify against')"
    USER_DIR="$USERS_DIR/$USER_NAME"

    if [ ! -f "$USER_DIR/$USER_NAME.crt" ]; then
        echo "Certificate for $USER_NAME not found."
        return
    fi

    if ! openssl verify -CAfile "$CA_DIR/ca.crt" -crl_check -CRLfile "$CRL_DIR/ca.crl" "$USER_DIR/$USER_NAME.crt"; then
        echo "Certificate for $USER_NAME is invalid or revoked."
        return
    fi

    openssl dgst -sha256 -verify <(openssl x509 -in "$USER_DIR/$USER_NAME.crt" -pubkey -noout) \
        -signature "$SIGNATURE" "$FILE"
    echo "Verification complete."
}

while true; do
    echo "\nPKI Management System"
    echo "1. Initialize PKI"
    echo "2. Create User"
    echo "3. Revoke User"
    echo "4. List Users"
    echo "5. Delete User"
    echo "6. Sign File"
    echo "7. Verify Signature"
    echo "8. Exit"

    read -p "Choose an option: " OPTION

    case $OPTION in
        1) initialize_pki ;;
        2) create_user ;;
        3) revoke_user ;;
        4) list_users ;;
        5) delete_user ;;
        6) sign_file ;;
        7) verify_signature ;;
        8) exit        ;;
        *) echo "Invalid option, please try again." ;;
    esac

done