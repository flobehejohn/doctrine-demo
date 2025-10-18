IMAGE ?= ghcr.io/$(ORG)/doctrine-demo:latest

build:
	docker build -t $(IMAGE) .

push:
	echo $$CR_PAT | docker login ghcr.io -u $$GH_USER --password-stdin
	docker push $(IMAGE)

k8s-apply:
	kubectl apply -f k8s
	kubectl rollout status deploy/doctrine-demo

latency-300:
	kubectl patch configmap doctrine-demo-config -p '{"data":{"latency_ms":"300"}}'
	kubectl rollout restart deploy doctrine-demo

latency-0:
	kubectl patch configmap doctrine-demo-config -p '{"data":{"latency_ms":"0"}}'
	kubectl rollout restart deploy doctrine-demo

load:
	bombardier -c 50 -d 120s -l -r 200 https://demo.ton-domaine.dev/search?query=test
