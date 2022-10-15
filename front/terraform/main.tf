data "aws_ssm_parameter" "invoke_url" {
  name = "/wordle/invokeURL"
}


# use pet name for dynamic front end bucket names, makes for easier burn and rebuild
#resource "random_pet" "frontend_bucket_name" {
#  prefix = "wordle-frontend-resources"
#  length = 2
#}

resource "aws_s3_bucket" "frontend_bucket" {
  bucket = "wordle-frontend-resources-oconnorj"
  force_destroy = "true"
}

resource "aws_s3_bucket_website_configuration" "example" {
  bucket = aws_s3_bucket.frontend_bucket.bucket

  index_document {
    suffix = "index.html"
  }
}

data "external" "frontend_build" {
  depends_on = [data.aws_ssm_parameter.invoke_url]
  program = ["bash", "-c", <<EOT
npm cache clear --force
echo "API_URL=${data.aws_ssm_parameter.invoke_url.value}" > .env && (npm ci && npm run build) >&2 && echo "{\"dest\": \"dist\"}"
EOT
  ]
  working_dir = "${path.module}/frontend"
  query = {
    param = "Hi from Terraform!"
  }
}

locals {
  mime_type_mappings = {
    html = "text/html",
    js   = "text/javacript",
    css  = "text/css"
  }
}

resource "aws_s3_bucket_object" "frontend_object" {
  for_each = fileset("${data.external.frontend_build.working_dir}/${data.external.frontend_build.result.dest}", "*")

  key          = each.value
  source       = "${data.external.frontend_build.working_dir}/${data.external.frontend_build.result.dest}/${each.value}"
  bucket       = aws_s3_bucket.frontend_bucket.bucket
  etag         = filemd5("${data.external.frontend_build.working_dir}/${data.external.frontend_build.result.dest}/${each.value}")
  content_type = lookup(local.mime_type_mappings, concat(regexall("\\.([^\\.]*)$", each.value), [[""]])[0][0], "application/octet-stream")

  // if you prefer an error if the MIME type is missing from mime_type_mappings
  // content_type = local.mime_type_mappings[concat(regexall("\\.([^\\.]*)$", each.value), [[""]])[0][0]]
}

# Boilerplate for the bucket

resource "aws_s3_bucket_policy" "default" {
  bucket = aws_s3_bucket.frontend_bucket.id
  policy = data.aws_iam_policy_document.default.json
}

data "aws_iam_policy_document" "default" {
  statement {
    actions = ["s3:GetObject"]

    resources = ["${aws_s3_bucket.frontend_bucket.arn}/*"]

    principals {
      type        = "AWS"
      identifiers = ["*"]
    }
  }
}

