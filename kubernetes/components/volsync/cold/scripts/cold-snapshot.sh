#!/bin/sh
TIMEOUT=900 # 15 minutes max wait for VolSync to pause

log() { echo "[$(date -u '+%Y-%m-%dT%H:%M:%SZ')] $*"; }

log "NAMESPACE: $NAMESPACE"
log "PVC: $PVC"
log "STATEFULSET: $STATEFULSET"
log "Waiting for VolSync to pause (status=WaitingForTrigger)..."
START=$(date +%s)
while true; do
    STATUS=$(kubectl get pvc $PVC -n $NAMESPACE -o jsonpath='{.metadata.annotations.volsync\.backube/latest-copy-status}' 2>/dev/null)
    CURRENT=$(date +%s)
    ELAPSED=$((CURRENT - START))

    if [ "$STATUS" = "WaitingForTrigger" ]; then
        log "VolSync is ready. Proceeding."
        break
    elif [ $ELAPSED -gt $TIMEOUT ]; then
        log "Timeout waiting for VolSync to pause. Aborting."
        exit 1
    fi
    sleep 5
done

# Scale to zero
log "Scaling down StatefulSet $STATEFULSET to 0 replicas..."
kubectl scale sts $STATEFULSET -n $NAMESPACE --replicas=0

# Wait for pods to terminate
log "Waiting for pods of $STATEFULSET to terminate..."
kubectl wait pods -l app.kubernetes.io/controller=$STATEFULSET -n $NAMESPACE --for=delete --timeout=300s || true
log "Pods terminated. StatefulSet $STATEFULSET is scaled down."

# Trigger VolSync copy
log "Triggering VolSync copy for PVC $PVC..."
TIMESTAMP=$(date +%s)
kubectl annotate pvc $PVC -n $NAMESPACE \
    volsync.backube/copy-trigger="$TIMESTAMP" --overwrite

# Wait for snapshot completion (poll status)
log "Waiting for VolSync copy to complete..."
while true; do
    STATUS=$(kubectl get pvc $PVC -n $NAMESPACE -o jsonpath='{.metadata.annotations.volsync\.backube/latest-copy-status}')
    if [ "$STATUS" = "Completed" ]; then
        log "VolSync copy completed."
        break
    fi
    sleep 10
done

# Scale back up
log "Scaling up StatefulSet $STATEFULSET to 1 replica..."
kubectl scale sts $STATEFULSET -n $NAMESPACE --replicas=1
log "StatefulSet $STATEFULSET scaled up."

# Cleanup trigger annotation (optional, keeps PVC clean)
kubectl annotate pvc $PVC -n $NAMESPACE \
    volsync.backube/copy-trigger-
