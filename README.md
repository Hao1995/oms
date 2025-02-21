# OMS 

As an Order Management System, integrating advertisements, orders, campaigns, etc.

Rund api server
```
bin/rails s
```

RabbiMQ test
```
rabbitmqadmin declare exchange name=campaign_exchange type=fanout durable=true
rabbitmqadmin declare queue name="my_temp_queue" durable="true" auto_delete="true"
rabbitmqadmin declare binding source=campaign_exchange destination=my_temp_queue
rabbitmqadmin get queue=my_temp_queue ackmode=ack_requeue_false
```