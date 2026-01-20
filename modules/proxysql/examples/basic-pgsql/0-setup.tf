terraform {
  required_providers {
    helm = {
      source  = "hashicorp/helm"
      version = "~> 2.4"
    }
  }
}

# you can pass helm provider config like `export KUBE_CONFIG_PATH=/path/to/k8s.kubeconfig`
provider "helm" {}


# make sure you have mysql server running at postgresql.localhost endpoint, you can use this helm command to setup one `helm upgrade --install -n localhost postgresql bitnami/postgresql --version 18.2.0 --set auth.postgresPassword=test # install postgres with user/pass postgres/test`
