# do-nomad-study

```bash
export AWS_PROFILE=<do-profile>
export AWS_S3_ENDPOINT=sgp1.digitaloceanspaces.com

export SPACES_ACCESS_TOKEN=<access_token>
export SPACES_SECRET_KEY=<secret_key>
export SPACES_BUCKET_NAME=<bucket-name>

terraform init \
 -backend-config="access_key=$SPACES_ACCESS_TOKEN" \
 -backend-config="secret_key=$SPACES_SECRET_KEY" \
 -backend-config="bucket=$SPACES_BUCKET_NAME"
```

