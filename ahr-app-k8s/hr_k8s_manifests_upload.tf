# Uploads the phpLDAPadmin manifests to the existing bootstrap bucket
# (hr-k8s-manifests-<account_id>) under the phpldapadmin/ prefix.
# The k3s server pulls them at boot.

resource "aws_s3_object" "phpldapadmin_manifests" {
  for_each = fileset("${path.module}/k8s-manifests", "**/*.yaml")

  bucket = "hr-k8s-manifests-${var.account_id}"
  key    = "phpldapadmin/${each.value}"
  source = "${path.module}/k8s-manifests/${each.value}"
  etag   = filemd5("${path.module}/k8s-manifests/${each.value}")
}
