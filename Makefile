.PHONY. : acr_build_push build_push

VER=0.0.4
export VER
acr_build_push :
	docker build -t todoapp:$(VER) . -f Dockerfile
	docker image tag todoapp:$(VER) charlescr.azurecr.io/todoapp:$(VER) 
	docker push charlescr.azurecr.io/todoapp:$(VER) 

ecr_build_push :
	docker build -t todoapp:$(VER) . -f Dockerfile
	docker image tag todoapp:$(VER) 230547346306.dkr.ecr.ap-northeast-2.amazonaws.com/todoapp:$(VER) 
	docker push 230547346306.dkr.ecr.ap-northeast-2.amazonaws.com/todoapp:$(VER) 

