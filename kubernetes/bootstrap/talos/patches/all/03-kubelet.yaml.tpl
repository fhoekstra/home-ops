apiVersion: v1alpha1
kind: KubeletConfig
config:
  maxPods: 250
  serializeImagePulls: false
  maxParallelImagePulls: 4
  imageGCLowThresholdPercent: 40
  imageGCHighThresholdPercent: 80
  imageMaximumGCAge: "168h" # One week
  imageMinimumGCAge: "12h"
---
apiVersion: v1alpha1
kind: KubeNodeConfig
nodeIP:
  validSubnets:
    - 192.168.1.0/24
