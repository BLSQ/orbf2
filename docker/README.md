# docker compose

the goal isn't not to be used as dev environment (make a seperate docker-compose.yml with hot reload)

test the "official" docker image "as if in prod/local hosting"

```
./script/docker_build
cd docker
# update .env HESABU_VERSION with the docker_build values
docker-compose up
```
