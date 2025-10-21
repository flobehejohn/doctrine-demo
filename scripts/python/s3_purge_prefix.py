#!/usr/bin/env python3

import argparse
import boto3
import sys


def main():
  parser = argparse.ArgumentParser()
  parser.add_argument("--bucket", required=True)
  parser.add_argument("--prefix", required=True)
  parser.add_argument("--dry-run", action="store_true")
  args = parser.parse_args()

  s3 = boto3.client("s3")
  to_delete = []
  paginator = s3.get_paginator("list_objects_v2")

  try:
    for page in paginator.paginate(Bucket=args.bucket, Prefix=args.prefix):
      for obj in page.get("Contents", []):
        to_delete.append({"Key": obj["Key"]})
        if len(to_delete) == 1000:
          if args.dry_run:
            print(f"[DRY] would delete {len(to_delete)} objects")
            to_delete.clear()
          else:
            s3.delete_objects(Bucket=args.bucket, Delete={"Objects": to_delete})
            to_delete.clear()
  except s3.exceptions.NoSuchBucket:
    print(f"Bucket {args.bucket} not found.", file=sys.stderr)
    return 1

  if to_delete:
    if args.dry_run:
      print(f"[DRY] would delete {len(to_delete)} objects")
    else:
      s3.delete_objects(Bucket=args.bucket, Delete={"Objects": to_delete})

  print("Done.")
  return 0


if __name__ == "__main__":
  sys.exit(main())
