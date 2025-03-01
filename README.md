# OMS 
As an Order Management System, integrating advertisements, orders, campaigns, etc.

## Quick Start - For End Users
1. Install docker

2. Copy .env
Generate `.env` file and fill in the corresponding information.
```
cp .env.example .env
```

3. Run services
This command runs the entire application, cron job, and databases.
```
make run
```

4. Open Campaigns page.
Click [link](http://localhost:3000/platforms/1/campaigns?page=1) to browse all campaigns of the Megaphone.
> Default platform is `megaphone` (id: 1) and is migrated automatically.
Then you can `Create`, `Edit`, `Delete`, and `Browse` a campaign.

5. Stop applications
```
make down
```

## Quick Start - For Developers
1. Install rvm
2. Install ruby 3.2.2 `rvm install 3.2.2`, `rvm use 3.2.2`
3. Install Docker

4. Copy .env
Generate `.env` file and fill in the corresponding information.
```
cp .env.example
```

5. Run databases and redis
```
make run-infra
```

6. Run app
```
bin/rails assets:precompile
bin/rails s
```

7. Run cron job (sidekiq)
```
bundle exec sidekiq
```

8. Open Campaign page
Click [link](http://localhost:3000/platforms/1/campaigns?page=1) to browse all campaigns belongs to Megaphone.
Then you can `Create`, `Edit`, `Delete`, and `Browse` a campaign.

9. Stop applications
```
make down-infra
```

## Run Test
1. Set up databases
```
make run-infra
```

2. Set up test schemas
```
RAILS_ENV=test rails db:create
RAILS_ENV=test rails db:migrate
```

3. Run all tests
```
make test
```

4. Check coverage
```
make open-coverage
```

5. Run a single test
```
bundle exec rspec spec/controllers/campaigns_controller_spec.rb --example "does not update and redirects with alert"
bundle exec rspec spec/controllers/campaigns_controller_spec.rb:56
```

## Thought Process
I decided to implement it with `A simple UI` and chose the following additional features to develop:
1. Support search function, pagination, sorting
2. Support archiving campaigns

In order to implement a UI easily, I decided to develop a MVC application using ROR.
For simplicity, I focused on the synchronization of the campaigns itself, so I didn't implement login system.
The following content we're going to talk about the `system architecture` and `database relationship`.

## System Architecture
![system-architecture](/doc/images/system-architecture.png)

### APP Service
Responsible for handling view and business logics. (Only mention special logics: create and update)

#### Create
Fetch the platform's create API first, so that even if the following reasons happen, we can still sync data back by the Cron Job.
- A network issue while the platform is returning a success response.
- Failed to insert the record to the database

#### Update
I thought the `archived` mean that we should delete the campaign on the platform. So any changes for the `archived` campaign should only change the database.
The following is detail update flow depends on different status, data content.
![update-flow](/doc/images/update-flow.png)

### Cron Jon
Responsible for sync data from the platform (Megaphone). Avoid missing any creation and outdated data made by the platform.
- Fetch platform's campaign data, find missing records then insert to our database.
- Fetch platform's campaign data and compare with our database, update the different data to our database.
    - In order to achieve multiple update at the same time, I use build-in function: upsert

## Database
The following is the current database table relationship.
![DB-ER](/doc/images/db-er.png)

The special part is the `customer_id` because the OMS should serve many customers(or clients). I set `customer_id` and platform's data as unique index to avoid conflict. We can also partition by `customer_id` to speed up the performance in the future.
