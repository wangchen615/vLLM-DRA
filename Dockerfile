# Use NVIDIA PyTorch image compatible with NVIDIA DRIVER 12.1 and CUDA Library 530.30.02
FROM nvcr.io/nvidia/pytorch:23.07-py3

# Set the base image Python version requirement
RUN python3 -m pip install --upgrade pip && \
    python3 -m pip install --upgrade setuptools

# Configure environment variable for CUDA libraries
ENV LD_LIBRARY_PATH=/usr/lib/x86_64-linux-gnu:$LD_LIBRARY_PATH

# Install vLLM libraries
RUN python3 -m pip install vllm

# Define the MODEL_NAME environment variable, with a default value
ENV MODEL_NAME=facebook/opt-125m

# Command to start the vLLM API server
CMD python -m vllm.entrypoints.openai.api_server --model ${MODEL_NAME}
