```bash
cd RustContainer
docker build . -t jupyter-rust
```

```bash
docker run -p 8899:8899 jupyter-rust:latest
```

Connect new notebook to jupyter server - use link from container output with token
