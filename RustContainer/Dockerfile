FROM jupyter/base-notebook:python-3.11

# Use bash for better error handling when piping installer scripts.
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

USER root

# Install build dependencies required by rustup and evcxr.
RUN apt-get update \
	&& apt-get install -y --no-install-recommends \
		build-essential \
		ca-certificates \
		curl \
		pkg-config \
	&& apt-get clean \
	&& rm -rf /var/lib/apt/lists/*

USER ${NB_UID}

# Configure Rust toolchain locations for the notebook user.
ENV RUSTUP_HOME=/home/${NB_USER}/.rustup \
	CARGO_HOME=/home/${NB_USER}/.cargo \
	PATH=/home/${NB_USER}/.cargo/bin:${PATH}

# Install Rust toolchain and register the evcxr Jupyter kernel.
RUN curl https://sh.rustup.rs -sSf | sh -s -- -y --profile minimal --no-modify-path \
	&& rustup component add rust-src clippy rustfmt \
	&& cargo install evcxr_jupyter \
	&& evcxr_jupyter --install \
	&& fix-permissions /home/${NB_USER} \
	&& fix-permissions "${CONDA_DIR}"

# Default command inherited from the base notebook image (start-notebook.sh)

EXPOSE 8899

CMD ["jupyter", "lab", "--ip=0.0.0.0", "--port=8899", "--allow-root", "--no-browser"]