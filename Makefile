.PHONY. : docker_image

VER=0.0.4
export VER
docker_image :
	docker build -t todoapp:$(VER) . -f Dockerfile
	docker image tag todoapp:$(VER) charlescr.azurecr.io/todoapp:$(VER) 
	docker push charlescr.azurecr.io/todoapp:$(VER) 
