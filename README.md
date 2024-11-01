# Laravel Container

Containerizing your Laravel App with [Docker](https://www.docker.com).

## How to Use

Clone this project in your Laravel APP.

```bash
cd your-laravel-app

git clone https://github.com/YilanBoy/laravel-container.git

cp laravel-container/.dockerignore ./.dockerignore
```

Then you can start to build container.

```bash
# build app
docker buildx build -f laravel-container/app.dockerfile --platform linux/amd64,linux/arm64 --push -t laravel-app:latest .

# build queue
docker buildx build -f laravel-container/queue.dockerfile --platform linux/amd64,linux/arm64 --push -t laravel-queue:latest .

# build scheduler
docker buildx build -f laravel-container/scheduler.dockerfile --platform linux/amd64,linux/arm64 --push -t laravel-scheduler:latest .
```
