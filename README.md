# Deploy vLLM server on Kubernetes using NVIDIA Kubernetes DRA driver.
The KubeCon AI day lightning talk to deploy vLLM server using DRA controller by NVIDIA

## Steps to deploy vLLM server with DRA

#### 1. Build the image that is compatible with DRA driver and cuda libaries
1. Choose the NVIDIA pytorch image version that is compatible with the following driver and cuda library version.
- NVIDIA DRIVER version: 12.1
- CUDA Library version: 530.30.02
- Torch version: `torch == 2.1.2`
- Python version: 3.9+
The supported PyTorch NVIDIA image is `nvcr.io/nvidia/pytorch:23.07-py3` according to the [compatibility matrix](https://docs.nvidia.com/deeplearning/frameworks/support-matrix/index.html).

The corresponding Dockerfile should start with the following:
```dockerfile
# Use NVIDIA PyTorch image compatible with NVIDIA DRIVER 12.1 and CUDA Library 530.30.02
FROM nvcr.io/nvidia/pytorch:23.07-py3

```


2. Configure the `LD_LIBRARY_PATH` env variable to include the host cuda libaries mounting path.
```dockerfile
# Configure environment variable for CUDA libraries
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
```

3. Install necessary python libraries and vLLM library.
```dockerfile
# Set the base image Python version requirement
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade setuptools

# Install vLLM libraries
RUN python3 -m pip install vllm
```

4. Configure a default model and allow it to be changed outside of the container.
```dockerfile
# Define the MODEL_NAME environment variable, with a default value
ENV MODEL_NAME=facebook/opt-125m
```

5. Start the vLLM openAI compatible API server.
```dockerfile
# Command to start the vLLM API server
CMD python -m vllm.entrypoints.openai.api_server --model ${MODEL_NAME}
```

#### 2. Adapt the deployment YAML
1. Remove the original resource limit that is on GPU, usually the key is `nvidia.com/gpu` or `nvidia.com/mig-2g.10gb` for MIG slice for example.
```yaml
        resources:
          limits:
            nvidia.com/gpu: 1
```

2. Define ResourceClaim for nvidia GPU to be consumed by the deployment.
```yaml
apiVersion: resource.k8s.io/v1alpha2
kind: ResourceClaim
metadata:
  namespace: gpu-test1
  name: gpu.nvidia.com
spec:
    resourceClassName: gpu.nvidia.com
```

3. Instantiate resourceClaim using the previous defined ResourceClaim in the deployment and reference the instantiated resource in the `resources` field of the deployment.
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: vllm
  labels:
    app: vllm-1gpu
spec:
  replicas: 1
  selector:
    matchLabels:
      app: vllm
  template:
    metadata:
      labels:
        app: vllm
    spec:
      containers:
      - name: vllm-container
        image: quay.io/chenw615/vllm_dra:latest
        imagePullPolicy: IfNotPresent
        command: ["python3", "-m", "vllm.entrypoints.openai.api_server", "--model", "${MODEL_NAME}"]
        ports:
        - containerPort: 8000
        env:
        - name: HUGGING_FACE_HUB_TOKEN
          valueFrom:
            secretKeyRef:
              name: huggingface-secret
              key: HF_TOKEN
        - name: MODEL_NAME
          value: "facebook/opt-125m"
        volumeMounts:
        - name: cache-volume
          mountPath: /root/.cache/huggingface
        resources:
          claims:
          - name: gpu
      resourceClaims:
      - name: gpu
        source:
          resourceClaimName: gpu.nvidia.com
      volumes:
      - name: cache-volume
        persistentVolumeClaim:
          claimName: huggingface-cache-pvc
```

### 3. Setting up a cluster installed with DRA controller and driver.
1. Follow the [NVIDIA k8s-dra-driver](https://github.com/NVIDIA/k8s-dra-driver/tree/main) tutorial to set up your node environment and start a kind cluster. The node env setup is skipped here.

2. Set up a `kind` cluster and install the `NVIDIA k8s-dra-driver`.

First, clone the NVIDIA k8s-dra-driver repo.
```bash
git clone https://github.com/NVIDIA/k8s-dra-driver.git
cd k8s-dra-driver
```

Then, create a `kind` cluster.
```bash
./demo/clusters/kind/create-cluster.sh
```

From there, we run their script to build the image for NVIDIA GPU resource driver and make the built image available to the `kind` cluster.
```bash
./demo/clusters/kind/build-dra-driver.sh
```

Then, we install the NVIDIA GPU DRA driver.
```bash
./demo/clusters/kind/install-dra-driver.sh
```

### 4. Deploy the vLLM server deployment.

### 5. Testing the vLLM server deployment
