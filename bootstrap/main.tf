# Bootstrap: bucket S3 donde vive el state remoto de todas las sucursales.
# Se aplica UNA sola vez con state local; después su propio state se mueve al bucket (ver README).

terraform {
  required_version = ">= 1.10"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
  # Credenciales: las toma del AWS CLI configurado en tu equipo, nunca del código.

  default_tags {
    tags = {
      Proyecto = "iac-sucursales"
      Sucursal = "compartido"
      Entorno  = "practica"
    }
  }
}

resource "aws_s3_bucket" "state" {
  #checkov:skip=CKV_AWS_18:Los logs de acceso necesitan otro bucket; fuera del alcance de la práctica.
  #checkov:skip=CKV_AWS_144:Replicar a otra región duplica el costo; el versionado ya permite recuperar el state.
  #checkov:skip=CKV_AWS_145:SSE-S3 (AES256) es gratis; una llave KMS propia cuesta $1/mes.
  #checkov:skip=CKV2_AWS_62:No se necesitan notificaciones de eventos del bucket.

  # AWS completa el nombre con un sufijo único (los nombres de bucket son globales).
  # Así el nombre no expone el ID de la cuenta.
  bucket_prefix = "iac-sucursales-tfstate-"

  lifecycle {
    # Borrar este bucket = perder el state de todas las sucursales.
    prevent_destroy = true
  }
}

# Versionado: cada apply guarda una versión nueva del state; si se corrompe, se recupera la anterior.
resource "aws_s3_bucket_versioning" "state" {
  bucket = aws_s3_bucket.state.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Cifrado en reposo con la llave administrada por S3 (gratis). El state puede contener datos sensibles.
resource "aws_s3_bucket_server_side_encryption_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "state" {
  bucket = aws_s3_bucket.state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Las versiones viejas del state se borran a los 90 días para que el bucket no crezca sin límite.
resource "aws_s3_bucket_lifecycle_configuration" "state" {
  bucket = aws_s3_bucket.state.id

  rule {
    id     = "limpiar-versiones-viejas"
    status = "Enabled"

    filter {}

    noncurrent_version_expiration {
      noncurrent_days = 90
    }

    abort_incomplete_multipart_upload {
      days_after_initiation = 7
    }
  }

  depends_on = [aws_s3_bucket_versioning.state]
}

# Solo se permite acceder por HTTPS (cifrado en tránsito).
resource "aws_s3_bucket_policy" "solo_https" {
  bucket = aws_s3_bucket.state.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "SoloHTTPS"
      Effect    = "Deny"
      Principal = "*"
      Action    = "s3:*"
      Resource  = [aws_s3_bucket.state.arn, "${aws_s3_bucket.state.arn}/*"]
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.state]
}
