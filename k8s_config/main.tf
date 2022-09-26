locals {
  target_url = "https://alef-target-app.azurewebsites.net/"
  final_url = local.target_url == "" ? data.terraform_remote_state.target.app_endpoint_url : "https://alef-target-app.azurewebsites.net/"
}

resource "kubectl_manifest" "create_namespace" {
    yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
   name: attack-ns
YAML
}

resource "kubectl_manifest" "start_stress_batch_jobs" {
    yaml_body = <<YAML
apiVersion: batch/v1
kind: Job
metadata:
  namespace: attack-ns
  name: attack-batch-job
  labels:
    app: attack-batch-job
spec:
  parallelism: ${var.k8s_job_parallelism}
  completions: ${var.k8s_job_parallelism}
  template:
    spec:
      containers:
      - name: attack-box
        image: alessiofilippin/just-another-boring-crawler-cli
        resources:
          limits:
            memory: "150Mi"
            cpu: "200m"
        args: ["BulkCall","${local.final_url}", "${var.number_of_threads}", "${var.duration_seconds}"]
      tolerations:
      - key: "node.kubernetes.io/memory-pressure"
        operator: "Exists"
        effect: "NoSchedule"
      restartPolicy: Never
  backoffLimit: 4
YAML
}