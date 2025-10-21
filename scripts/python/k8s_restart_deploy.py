#!/usr/bin/env python3

import argparse
import time

from kubernetes import client, config


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--namespace", "-n", default="default")
  parser.add_argument("--name", required=True)
  args = parser.parse_args()

  try:
    config.load_kube_config()
  except Exception:
    config.load_incluster_config()

  api = client.AppsV1Api()
  deployment = api.read_namespaced_deployment(args.name, args.namespace)

  annotations = deployment.spec.template.metadata.annotations or {}
  annotations["devops.ocsi/restartedAt"] = time.strftime("%Y-%m-%dT%H:%M:%SZ", time.gmtime())
  deployment.spec.template.metadata.annotations = annotations

  api.patch_namespaced_deployment(args.name, args.namespace, deployment)
  print(f"Rollout restarted for {args.namespace}/{args.name}")


if __name__ == "__main__":
  main()
