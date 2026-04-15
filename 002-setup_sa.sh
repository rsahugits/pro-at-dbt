# Setting up a service account for dbt in Snowflake.
# DBT will use this service account to connect to Snowflake and perform data transformations.

# Generate a private key for the service account. This key will be used to authenticate the service account when connecting to Snowflake.
openssl genrsa 2048 | openssl pkcs8 -topk8 -v2 des3 -inform PEM -out ~/.ssh/sf_rsa_key.p8

# Generate the public key from the private key.
openssl rsa -in ~/.ssh/sf_rsa_key.p8 -pubout -out ~/.ssh/sf_rsa_key.pub

