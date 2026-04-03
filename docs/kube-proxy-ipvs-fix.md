# kube-proxy iptables → IPVS Fix (Docker Desktop + kind)

## Date

2026-04-03

## Symptom

- Blazor frontend login shows "Logging in..." indefinitely, then times out after 20 seconds.
- Frontend logs confirm the HTTP request is sent (`POST http://seriescatalog-api:8080/auth/login`) but never receives a response.
- API logs show **zero** incoming requests from the frontend — only health-check probes appear.
- Direct `PowerShell` / `curl` requests to `http://localhost/auth/login` (via ingress) work perfectly and return in ~40ms.
- Kubernetes health probes (`/api/health`) on the API pod pass consistently.

## Investigation

### 1. Pod IP vs ClusterIP service

A temporary curl pod in the `seriescatalog` namespace was used to isolate the layer:

| Target | Result |
|---|---|
| Pod IP (`http://10.244.0.54:8080/api/health`) | **200 OK** — instant response |
| ClusterIP service (`http://10.96.50.167:8080/api/health`) | **Connection timed out** after 10s |
| DNS name (`http://seriescatalog-api:8080/api/health`) | **Connection timed out** (resolves to the same ClusterIP) |

This confirmed the issue was **ClusterIP service routing**, not the API application, DNS, or pod networking.

### 2. Why ingress and health probes still worked

- **Ingress controller** (ingress-nginx) routes traffic directly to **pod IPs** via the Endpoints API — it does not use ClusterIP service addresses. That's why `http://localhost/auth/login` via ingress worked fine.
- **kubelet health probes** also target pod IPs directly (`httpGet` on `containerPort`), so readiness/liveness probes were unaffected.
- The **frontend pod**, however, uses a Kubernetes Service DNS name (`http://seriescatalog-api:8080`) which resolves to the ClusterIP. This path was completely broken.

### 3. kube-proxy error logs

```
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=20
```

Revealed a continuous sync failure loop:

```
E0403 20:05:18.504184  1 proxier.go:1501] "Failed to execute iptables-restore"
  err=<
    exit status 4:
    Warning: Extension recent revision 0 not supported, missing kernel module?
    Warning: Extension recent is not supported, missing kernel module?
    iptables-restore v1.8.9 (nf_tables):
    line 114: RULE_APPEND failed (No such file or directory):
      rule in chain KUBE-SVC-VWJEL7HXVNV6CNNN
    line 117: RULE_APPEND failed (No such file or directory):
      rule in chain KUBE-SEP-LUIE3OMFNBHE5H6V
  > ipFamily="IPv4"
I0403 20:05:18.504306  1 proxier.go:768] "Sync failed" ipFamily="IPv4" retryingTime="30s"
```

This repeated every ~30 seconds. The iptables rules for the `seriescatalog-api` service were **never installed**.

## Root cause

Docker Desktop (with kind) uses a Linux kernel that has moved to **nftables** as the underlying packet-filtering framework. However, kube-proxy was configured in `iptables` mode, which uses the legacy `iptables-restore` binary. The key incompatibility:

1. The `xt_recent` kernel module is **not loaded** (and may not be available), causing `Extension recent is not supported, missing kernel module?`.
2. `iptables-restore` runs against the `nf_tables` backend (note: `iptables-restore v1.8.9 (nf_tables)`), but certain chain/rule operations fail with `No such file or directory`.
3. Because the sync fails, **no DNAT rules** are created for ClusterIP services. Packets sent to a ClusterIP address are simply dropped — they have nowhere to go.

### Why nftables mode also failed

Switching to `mode: nftables` was attempted first but failed with:

```
Error: Could not process rule: No such file or directory
add rule ip kube-proxy external-TAO5FKKM-... fib saddr type local jump mark-for-masquerade
                                               ^^^^^^^^^^^^^^
```

The `fib` expression requires the `nft_fib` kernel module, which was also not loaded in the Docker Desktop VM.

## Fix applied

Switched kube-proxy to **IPVS mode**, which uses the Linux IPVS (IP Virtual Server) subsystem instead of iptables or nftables for service load balancing.

### Steps

1. **Patched the kube-proxy ConfigMap:**

   ```powershell
   kubectl get configmap kube-proxy -n kube-system -o json |
     ConvertFrom-Json |
     ForEach-Object {
       $config = $_.data.'config.conf' -replace 'mode: iptables', 'mode: ipvs'
       $_.data.'config.conf' = $config
       $_
     } |
     ConvertTo-Json -Depth 10 |
     kubectl apply -f -
   ```

2. **Restarted kube-proxy to pick up the change:**

   ```powershell
   kubectl delete pod -n kube-system -l k8s-app=kube-proxy
   kubectl wait --for=condition=ready pod -n kube-system -l k8s-app=kube-proxy --timeout=30s
   ```

3. **Verified clean startup** — no errors in kube-proxy logs:

   ```
   I0403 20:07:39.867056  1 server_linux.go:189] "Using ipvs Proxier"
   I0403 20:07:39.867759  1 proxier.go:353] "IPVS scheduler not specified, use rr by default"
   ```

4. **Verified ClusterIP service routing** — curl pod successfully reached `http://seriescatalog-api:8080/api/health` via ClusterIP.

5. **Verified end-to-end login** — `POST /auth/login` through the frontend's HttpClient now reaches the API in ~39ms.

## Scope of impact

- This is a **cluster-level** change (kube-proxy ConfigMap in `kube-system`).
- It persists until the kind cluster is recreated.
- If the cluster is torn down and recreated, this fix must be reapplied.
- IPVS mode uses round-robin scheduling by default, which is appropriate for this workload.

## How to verify

```powershell
# Check kube-proxy mode
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=5 | Select-String "Proxier"

# Check for sync errors
kubectl logs -n kube-system -l k8s-app=kube-proxy --tail=20 | Select-String "Sync failed|Failed to execute"

# Test service connectivity from a pod
kubectl run curl-test --rm -i --restart=Never -n seriescatalog --image=curlimages/curl:latest -- `
  curl -s --max-time 5 http://seriescatalog-api:8080/api/health
```
