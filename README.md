# Docker container to run cpu based dxvk

```bash
docker buildx build . --tag dxvk_test
docker run --rm -it dxvk_test xvfb
docker run --rm -it dxvk_test xorg
```
