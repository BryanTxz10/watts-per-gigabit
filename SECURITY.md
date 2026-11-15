# Security policy

This is a public research-software repository. It contains no production
service, but it does describe how to operate shared testbed infrastructure
(Grid'5000 and a private bench). The rules below exist to keep testbed
credentials and private network details out of the public history.

## Never commit

- Grid'5000 credentials: account passwords, SSH private keys, OAR job
  tokens, `~/.python-grid5000.yaml`, or API tokens of any kind.
- Kubeconfig files, Ansible Vault passwords or decrypted vault files,
  TLS keys, `.env` files.
- Real Ansible inventories (`ansible/inventory/*.yml`). Only
  `*.example.yml` templates with placeholder hostnames and addresses are
  tracked. The `.gitignore` enforces this; do not bypass it with `git add -f`.
- Subscriber keys (K, OPc) for anything other than the public test values
  used by UERANSIM and Open5GS examples.
- Raw packet captures that may contain third-party traffic.

If a secret is committed by mistake, rotate it first, then rewrite history
and force-push, and record the incident in the logbook.

## Reporting a vulnerability

The project has no attack surface of its own; if you find a problem in the
harness or the deployment code that could expose a testbed, open a GitHub
issue without the sensitive details and ask for a private channel.
