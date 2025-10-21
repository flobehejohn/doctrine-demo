#!/usr/bin/env python3

import argparse
import datetime as dt

from azure.containerregistry import ContainerRegistryClient
from azure.identity import DefaultAzureCredential


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--registry", required=True, help="ex: doctrinepocacr.azurecr.io")
  parser.add_argument("--repository", required=True, help="ex: doctrine-demo-app")
  parser.add_argument("--older-than-days", type=int, default=7)
  args = parser.parse_args()

  credential = DefaultAzureCredential()
  client = ContainerRegistryClient(f"https://{args.registry}", credential)

  cutoff = dt.datetime.utcnow() - dt.timedelta(days=args.older_than_days)
  cutoff = cutoff.replace(tzinfo=dt.timezone.utc)

  deleted = 0
  for manifest in client.list_manifest_properties(args.repository):
    last_updated = manifest.last_updated_on
    if (
      not manifest.tags
      and last_updated is not None
      and last_updated < cutoff
    ):
      client.delete_manifest(args.repository, manifest.digest)
      deleted += 1

  print(f"Deleted {deleted} untagged manifests older than {args.older_than_days} days.")


if __name__ == "__main__":
  main()
