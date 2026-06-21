# uploads the k8s manifests to a bucket

resource "aws_s3_object" "phpldapadmin_manifests" {
  for_each = fileset("${path.module}/k8s-manifests", "**/*.yaml")

  bucket = "hr-k8s-manifests-${var.account_id}"
  key    = "phpldapadmin/${each.value}"
  source = "${path.module}/k8s-manifests/${each.value}"
  etag   = filemd5("${path.module}/k8s-manifests/${each.value}")
}
