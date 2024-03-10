# vLLM-DRA
The KubeCon AI day lightning talk to deploy vLLM server using DRA controller by NVIDIA

## Steps in container
1. Choose the NVIDIA pytorch image version that is compatible with the following driver and cuda library version.
- NVIDIA DRIVER version: 12.1
- CUDA Library version: 530.30.02
- Torch version: `torch == 2.1.2`
- Python version: 3.9+
The supported PyTorch NVIDIA image is `nvcr.io/nvidia/pytorch:23.07-py3` according to the [compatibility matrix](https://docs.nvidia.com/deeplearning/frameworks/support-matrix/index.html).


2. Configure the `LD_LIBRARY_PATH` env variable to include the host cuda libaries mounting path.
```bash
export LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH
```

3. Install vLLM libraries
```
pip install vllm
```

4. Start the vLLM openAI compatible API server.
```
python -m vllm.entrypoints.openai.api_server --model facebook/opt-125m
```


