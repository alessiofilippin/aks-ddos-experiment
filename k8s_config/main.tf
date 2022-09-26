resource "kubectl_manifest" "create_namespace" {
    yaml_body = <<YAML
apiVersion: v1
kind: Namespace
metadata:
   name: attack-ns
YAML
}

resource "kubectl_manifest" "start_stress_deployment_jobs" {
    yaml_body = <<YAML
apiVersion: apps/v1
kind: Deployment
metadata:
  namespace: attack-ns
  name: attack-deployment
  labels:
    app: attack-deployment
spec:
  replicas: 50
  selector:
    matchLabels:
      app: attack-deployment
  template:
    metadata:
      labels:
        app: attack-deployment
    spec:
      topologySpreadConstraints:
        - maxSkew: 1
          topologyKey: kubernetes.io/hostname
          whenUnsatisfiable: DoNotSchedule
          labelSelector:
            matchLabels:
              app: attack-deployment
      containers:
      - name: attack-box
        image: alessiofilippin/just-another-boring-crawler-cli
        resources:
          limits:
            memory: "250Mi"
            cpu: "200m"
          requests:
            memory: "10Mi"
            cpu: "10m"
        args: ["BulkCall","${data.terraform_remote_state.target.outputs.app_endpoint_url}", "${var.number_of_threads}", "${var.duration_seconds}", "http://${data.terraform_remote_state.squid.outputs.global_lb_ip}:3129"]
      tolerations:
      - key: "node.kubernetes.io/memory-pressure"
        operator: "Exists"
        effect: "NoSchedule"
      restartPolicy: Always
YAML

  depends_on = [
    kubectl_manifest.create_namespace
  ]
}