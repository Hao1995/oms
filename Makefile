.PHONY: check-lint, fix-lint, test, open-coverage, run, run-infra, down, down-infra

check-lint:
	bin/rubocop -f github 

fix-lint:
	bin/rubocop -A

test:
	bundle exec rspec

open-coverage:
	open coverage/index.html

down-infra:
	docker-compose down

run-infra:
	docker-compose up -d

down:
	docker-compose --profile app down

run:
	docker-compose --profile app up --force-recreate