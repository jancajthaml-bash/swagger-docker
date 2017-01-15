NAME = jancajthaml/swagger
VERSION = latest
CORES := $$(getconf _NPROCESSORS_ONLN)

.PHONY: all image tag_git tag publish clean

all: image clean

image:
	docker build -t $(NAME):$(VERSION) .

tag_git:
	git checkout -B release/$(VERSION)
	git branch --set-upstream-to=origin/release/$(VERSION) release/$(VERSION)
	git pull --tags
	git add --all
	git commit -a --allow-empty-message -m ''
	git rebase --no-ff --autosquash release/$(VERSION)
	git push origin release/$(VERSION)

run: image
	docker run --rm -it -v data:/etc/swagger -p 127.0.0.1:9300:9300 $(NAME):$(VERSION)

tag: image tag_git
	docker export $$(docker ps -q -n=1) | docker import - $(NAME):stripped
	docker tag $(NAME):stripped $(NAME):$(VERSION)
	docker rmi $(NAME):stripped

publish: tag
	docker push $(NAME)
	make clean

clean:
	docker images | grep -i "^<none>" | awk '{ print $$3 }' | xargs -P$(CORES) -I{} docker rmi -f {}
	docker ps -a | grep Exit | cut -d ' ' -f 1 | xargs -P$(CORES) -I{} docker rm -f {}
	zombies=$$(docker volume ls -qf dangling=true)
	[ $$($$zombies | wc -l) -gt 0 ] && docker volume rm $$zombies || true