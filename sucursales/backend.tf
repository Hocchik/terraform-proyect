# State remoto en el bucket creado por bootstrap/. Cada workspace (= grupo) tiene su archivo:
#   grupos/<grupo>/sucursales.tfstate
# use_lockfile: bloqueo nativo en S3 (archivo .tflock), sin DynamoDB (Terraform >= 1.10).
terraform {
  backend "s3" {
    bucket               = "iac-sucursales-tfstate-20261016220316735500000001"
    key                  = "sucursales.tfstate"
    workspace_key_prefix = "grupos"
    region               = "us-east-2"
    encrypt              = true
    use_lockfile         = true
  }
}
