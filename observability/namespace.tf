# Every chart in this root lands in one namespace, created here rather than by
# whichever helm_release happens to be applied first.
resource "kubernetes_namespace" "this" {
  metadata {
    name = var.namespace
  }
}
