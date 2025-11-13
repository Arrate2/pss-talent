resource "aws_s3_bucket" "mi_bucket_ejemplo" {
  bucket = "claudia-ae-pss" 

  tags = {
    Name        = "MiBucketDesdeTerraform"
    Environment = "Dev"
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.mi_bucket_ejemplo.id
  block_public_acls       = true
  block_public_policy     = false # <--
  ignore_public_acls      = true
  restrict_public_buckets = false # <--
}

# 1. Definir el documento de política IAM
data "aws_iam_policy_document" "public_read_access" {
  statement {
    principals {
      type        = "AWS"
      identifiers = ["*"] #<--permite acceso público
    }

    actions = [
      "s3:GetObject",
    ]

    resources = [
      aws_s3_bucket.mi_bucket_ejemplo.arn,
      "${aws_s3_bucket.mi_bucket_ejemplo.arn}/*", # Esto incluye todos los objetos dentro del bucket
    ]
  }
}

# 2. Aplicar la política al bucket
resource "aws_s3_bucket_policy" "public_read_policy" {
  bucket = aws_s3_bucket.mi_bucket_ejemplo.id
  # El campo 'policy' toma la salida del documento IAM definido arriba
  policy = data.aws_iam_policy_document.public_read_access.json
}
# Parte 6 
resource "aws_s3_bucket_website_configuration" "website_config" {
  bucket = aws_s3_bucket.mi_bucket_ejemplo.id
  index_document {
    suffix = "index.html"
  }
  error_document {
    key = "error.html"
  }
}
#Parte 8
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.mi_bucket_ejemplo.id
  key          = "index.html"
  source       = "index.html" 
  content_type = "text/html"
  etag         = filemd5("index.html") #para mantener cambios locales
  tags = {
    Project     = "StaticWebsite"
    ManagedBy   = "Terraform"
    ContentRole = "FilePage"
  }
}

# Carga de error.html
resource "aws_s3_object" "error" {
  bucket       = aws_s3_bucket.mi_bucket_ejemplo.id
  key          = "error.html"
  source       = "error.html" 
  content_type = "text/html"
  etag         = filemd5("error.html") #para mantener cambios locales
  tags = {
    Project     = "StaticWebsite"
    ManagedBy   = "Terraform"
    ContentRole = "ErrorPage"
  }
 }