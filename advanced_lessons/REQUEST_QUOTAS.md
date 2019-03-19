# Limiting API usage

## Prerequisites
- [API keys enabled for your service](API_KEYS.md)
## Enabling quotas
So we looked at the usage of [API keys](API_KEYS.md) to restrict access to your API and [TLS](TLS.md) to secure the communication channel, but how do you ensure that your API is not overused to avoid performance and stability issues?

*__Quotas to the rescue!__*

Quoats are defined in your ```api_config.yaml```
They consist of 3 different components:
The ```metrics``` block describes the overall metric including the name of the metric, the datatype of the metric unit and the metric type (currently the ESP only supports ```metric_kind: DELTA```)  
The ```quota.limits``` block defines the actual limit which should be enforced.  
And the ```quota.metric_rules``` maps the limit to the respective API mathods.

So, let's talk code...
Take a look at this code snippet.
```
metrics:
  # Define a metric for read requests.
  - name: "yages-read-requests"
    display_name: "Read requests"
    value_type: INT64
    metric_kind: DELTA
quota:
  limits:
    # Define the limit or the read-requests metric.
    - name: "yages-request-limit"
      metric: "yages-read-requests"
      unit: "1/min/{project}"
      values:
        STANDARD: 10
  metric_rules:
    - metric_costs:
        "yages-read-requests": 1
      selector: yages.Echo.Ping
    - metric_costs:
        "yages-read-requests": 2
      selector: yages.Echo.Reverse
```
The first block defines your metric. It contains the name which is used in the Google Web Console to display your metric, the datatype of the metric unit and the type if the metric.  

The next block ```quota.limits``` defines a single quota which will be enforced. It consists is mapped to a metric using the ```metric: [YOUR METRIC NAME]``` element and specifies the unit of the quota ```unit: "1/min/{project}"``` which let's the ESP count requests each minute for each project (API Key). Finally the ```values``` part defines the actual value of allowed requests per minute and API key.  
The third block maps the metric to the different API methods and assigns a "cost" factor to each method.  

This means that you can assign a weight for a request to reflect computing cost of different methods into the quota. In our example a call to the ```Reverse``` method would use up 2 units of our allwoed 10/min while the ```Ping``` method only costs us 1 unit.

Now let's try it out.
Append the above code in your ```api_config.yaml``` and update your deployment.

```
gcloud endpoints services deploy api_descriptor.pb api_config.yaml
```

Now in order to test the feature efficiently we will need a second API key and 2 sperate GRPC clients.

You already should have one API key from going through the [API Keys](API_KEYS.md) tutorial. So, just create a second one as described.

In 2 different terminals spin up two containers with GRPCURL and test away.
```
##### CLIENT 1 #####
docker run --name grpcclient_1 --rm -it quay.io/mhausenblas/gump:0.1 sh

# inside the container
grpcurl \
--plaintext \
-H "x-api-key: [API-KEY_1]" \
[your-service-url]:50000 yages.Echo.Ping


##### CLIENT 2 #####
docker run --name grpcclient_2 --rm -it quay.io/mhausenblas/gump:0.1 sh

# inside the container
grpcurl \
--plaintext \
-H "x-api-key: [API-KEY_2]" \
[your-service-url]:50000 yages.Echo.Ping
```

## Further Reading:
-  https://cloud.google.com/endpoints/docs/grpc/quotas-configure