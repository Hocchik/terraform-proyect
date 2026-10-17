# El bootstrap guarda su propio state en el bucket que él mismo creó.
# Se agregó DESPUÉS del primer apply (con state local) y se movió con: terraform init -migrate-state
terraform {
  backend "s3" {
    bucket       = "iac-sucursales-tfstate-20261016220316735500000001"
    key          = "bootstrap/terraform.tfstate"
    region       = "us-east-2"
    encrypt      = true
    use_lockfile = true
  }
}
