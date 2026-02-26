kind: Cluster
apiVersion: kind.x-k8s.io/v1alpha4
name: __KIND_CLUSTER_NAME__
containerdConfigPatches:
  - |-
    [plugins."io.containerd.grpc.v1.cri".registry.mirrors."__LOCAL_REGISTRY_HOST__:__LOCAL_REGISTRY_PORT__"]
      endpoint = ["http://__REGISTRY_CONTAINER_NAME__:5000"]
nodes:
  - role: control-plane
    extraPortMappings:
      - containerPort: 80
        hostPort: __KIND_INGRESS_HTTP_PORT__
        protocol: TCP
      - containerPort: 443
        hostPort: __KIND_INGRESS_HTTPS_PORT__
        protocol: TCP
  - role: worker
