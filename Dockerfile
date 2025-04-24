ARG TARGET=production
FROM nvcr.io/nvidia/cuda-dl-base:24.12-cuda12.6-devel-ubuntu24.04 as production
FROM ubuntu:24.04 as ci

RUN apt-get update && apt-get install -y \
    software-properties-common \
    && add-apt-repository -y ppa:deadsnakes/ppa \
    && apt-get update

RUN apt-get install -y \
    python3.10 \
    python3.10-venv \
    python3.10-dev \
    && update-alternatives --install /usr/bin/python3 python3 /usr/bin/python3.10 1

RUN apt-get install -y \
    python3-pip \
    git \
    build-essential \
    libjpeg-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

RUN python3.10 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

RUN pip install --no-cache-dir --upgrade pip setuptools wheel

ARG TORCH_VERSION=2.5.1+cu121
ARG TORCH_INDEX_URL=https://download.pytorch.org/whl/cu121

RUN pip install --no-cache-dir \
    torch==${TORCH_VERSION} \
    --index-url ${TORCH_INDEX_URL}

RUN git clone https://github.com/xmarva/transformer-based-architectures.git
WORKDIR /transformer-based-architectures

COPY requirements.txt .

RUN if [ "$TARGET" = "ci" ]; then \
    sed -i '/GPUtil/d' requirements.txt && \
    git clone https://github.com/anderskm/gputil.git /tmp/gputil && \
    cd /tmp/gputil && \
    sed -i 's/description-file/description_file/g' setup.cfg && \
    python3 setup.py install && \
    cd - ; \
    fi

RUN pip install --no-cache-dir -r requirements.txt

COPY docker-entrypoint.sh /usr/local/bin/
RUN sed -i 's/\r$//' /usr/local/bin/docker-entrypoint.sh \
    && chmod +x /usr/local/bin/docker-entrypoint.sh

ENTRYPOINT ["docker-entrypoint.sh"]

# docker build -t transformer-based-gpu .
# docker run -it --rm -p 8888:8888 --gpus all --env-file .env -v C:/Users/User/transformer-based-gpu:/transformer-based-gpu --entrypoint /bin/bash transformer-based-gpu -c "/usr/local/bin/docker-entrypoint.sh && exec /bin/bash"
# python -c "import torch; print(torch.cuda.is_available())"
# jupyter notebook --ip=0.0.0.0 --no-browser --allow-root