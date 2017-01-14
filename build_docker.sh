#!/bin/bash

set -e

[ $(uname) == "Darwin" ] && command -v docker-machine > /dev/null 2>&1 && {
  docker-machine ssh $(docker-machine active) "sudo udhcpc SIGUSR1 && sudo /etc/init.d/docker restart"
}

docker build -t jancajthaml/swagger .

docker run --privileged jancajthaml/swagger /bin/true

#docker run -p 8080:8080 jancajthaml/swagger

if [ "$(uname)" = "Darwin" ]; then
  docker-machine ssh dev -f -N -L 8080:localhost:8080
fi