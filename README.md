# OMS 
As an Order Management System, integrating advertisements, orders, campaigns, etc.

## Quick Start - For End Users
Prerequisites:
1. Install docker

This command runs the entire application, cron job, and databases.
```
make run
```

Click [link](http://localhost:3000/platforms/1/campaigns?page=1) to browse all campaigns belongs to Megaphone.
Then you can `Create`, `Edit`, `Delete`, and `Browse` a campaign.

Stop applications
```
make down
```

## Quick Start - For Developers
Prerequisites:
1. Install rvm
2. Install ruby 3.2.2 `rvm install 3.2.2`, `rvm use 3.2.2`
3. Install Docker

This command runs databases.
```
make run-infra
```

Run app
```
bin/rails assets:precompile
bin/rails s
```

Run cron job (sidekiq)
```
bundle exec sidekiq
```

Click [link](http://localhost:3000/platforms/1/campaigns?page=1) to browse all campaigns belongs to Megaphone.
Then you can `Create`, `Edit`, `Delete`, and `Browse` a campaign.

Stop applications
```
make down-infra
```

## Run Test
Set up databases
```
make run-infra
```

Set up test schemas
```
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate
```

Run all tests
```
bundle exec rspec
```

Check coverage
```
open coverage/index.html
```

Run a single test
```
bundle exec rspec spec/controllers/campaigns_controller_spec.rb --example "does not update and redirects with alert"
bundle exec rspec spec/controllers/campaigns_controller_spec.rb:56
```

