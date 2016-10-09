PWD=$(shell pwd)
NAME="es"
IMAGE="myes"

init:
	mkdir -p config/scripts
	mkdir -p data
	touch config/userdict_ja.txt
	docker run --name $(NAME) elasticsearch plugin install analysis-kuromoji
	docker commit $(NAME) $(IMAGE)
	docker rm -f $(NAME)

start:
	docker run -d --name $(NAME) -p 9200:9200 \
		-v $(PWD)/config:/usr/share/elasticsearch/config \
		-v $(PWD)/data:/usr/share/elasticsearch/data \
		$(IMAGE) elasticsearch

stop:
	docker rm -f $(NAME)

shell:
	docker exec -it $(NAME) bash

kibana:
	docker run --rm --link $(NAME):elasticsearch -p 5601:5601 kibana

