# Restricting Access to your API through API KEYS

In order to secure your API, we need to update the ```api_config.yaml```

Open the file in the project root and change the following lines:

```
usage:
  rules:
  ### allow public access to all API's
  - selector: "*"
    allow_unregistered_calls: true
```

into:

```
usage:
  rules:
    ### only reflection can be called without an API Key
  - selector: yages.Echo.Ping
    allow_unregistered_calls: false
  - selector: grpc.reflection.v1alpha.ServerReflection.ServerReflectionInfo
    allow_unregistered_calls: true
```

Deploy the change using:
```
gcloud endpoints services deploy api_descriptor.pb api_config.yaml
```

Now try to call your ```Ping``` Interface:
```
docker run --name grpcclient --rm -it quay.io/mhausenblas/gump:0.1 sh

# inside the container
grpcurl --plaintext [your-service-url]:50000 yages.Echo.Ping
```

You will see that the access is denied.  
So let's create an API key.

(gcloud unfortunatly does not yet provide an API to manage keys from the CLI, so we need to use the Web Console)

- Make sure you have the correct project selected in the top pane of the console
- go to API & Services -> Credentials in the left menu pane
- click "Create Credentials" -> "API Key"
- for minimum security at least restrict the key to our Yages API (Restrict -> API restriction -> select our Yages API)
- it can take up to 5 minutes until the API key is valid!

So, let's see if we can call our API:

```
docker run --name grpcclient --rm -it quay.io/mhausenblas/gump:0.1 sh

# inside the container
grpcurl \
--plaintext \
-H "x-api-key: [API-KEY]" \
[your-service-url]:50000 yages.Echo.Ping
```

## Further Reading

- https://cloud.google.com/endpoints/docs/grpc/restricting-api-access-with-api-keys?hl=en