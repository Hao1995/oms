.PHONY: run, run-infra, down

down-infra:
	docker-compose down

run-infra:
	docker-compose up -d

down:
	docker-compose --profile app down

run:
	docker-compose --profile app up --force-recreate