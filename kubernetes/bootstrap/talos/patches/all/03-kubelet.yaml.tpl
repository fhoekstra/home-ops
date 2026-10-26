# Kubelet settings stay in the deprecated v1alpha1 form for now: the generated
# KubeletConfig document conflicts with ANY .machine.kubelet content, and
# machine.kubelet.extraMounts (the csi-local-hostpath bind mount, see
# node/<host>/06-kubelet-extra-mounts.yaml) has no multi-doc replacement.
# The kubelet configuration moves to KubeletConfig/KubeNodeConfig together with
# the move to UserVolumeConfig + workload isolation (separate branch).
apiVersion: v1alpha1
kind: KubeletConfig
$patch: delete
---
apiVersion: v1alpha1
kind: KubeNodeConfig
$patch: delete
---
machine:
  kubelet:
    # The tag comes from kubernetesVersion in topf.yaml, which is what
    # Renovate tracks (same datasource comment as before the migration).
    image: ghcr.io/siderolabs/kubelet:{{ .KubernetesVersion }}
    extraConfig:
      maxPods: 250
      serializeImagePulls: false
      maxParallelImagePulls: 4
      imageGCLowThresholdPercent: 40
      imageGCHighThresholdPercent: 80
      imageMaximumGCAge: "168h" # One week
      imageMinimumGCAge: "12h"
    defaultRuntimeSeccompProfileEnabled: true
    disableManifestsDirectory: true
    nodeIP:
      validSubnets:
        - 192.168.1.0/24
