# GRPC field test on Google cloud

## Intention

This project is meant to be a simple benchmark of Google Cloud Enpoints and their GRPC support.
Ideally at the end we have an API which could be published to the world (incl. the business side like payment plans).
Topics that should be covered:
- deplyoment of the API
- basic security (TLS, use of API keys)
- multi-tenancy (with self sign-on)
- public API documentation

## References

This example uses a fork of the YAGES grpc echo server:
https://github.com/mhausenblas/yages

A snapshot of the project is contained in the ``` /yages ``` folder.
There are some changes to YAGES compared to it's original repository.
Please refer to [CHANGELOG.md](./yages/CHANGELOG.md) for details.

## Preparations

- create your Google Cloud account to start a free trial
  - you will get $300 and the Google free tier to play around with Google Cloud for 1 year
  - this tutorial will only use free-tier resources and won't cost a dime ;-)
- install the [Google Cloud SDK](https://cloud.google.com/sdk/install) on your local machine
- [initialize the SDK](https://cloud.google.com/sdk/docs/initializing) on your local machine
- create a new Google Cloud project
- have the [protoc Protobuf compiler](https://github.com/protocolbuffers/protobuf) ready on your local machine 


## Build & Deploy

After following these steps you will have:
 - a Google Cloud Compute Engine instance of type f1-micro
 - a running deployment of the Yages GRPC server
 - a running ESP container
 - a configured Cloud Endpoints API

 Advanced lessons are available for:
 - [TLS activated for your API](./advances_lessons/TLS.md)
 - enable [API keys](./advances_lessons/API_AUTH.md)
 - configure [quotas](./advances_lessons/REQUEST_QUOTAS.md)

### Let's start

  1. Create your Google Cloud Compute Engine instance
  ``` 
  gcloud compute --project=grpc-field-test instances create grpc-test-vm \
  --zone=us-east1-b \
  --machine-type=f1-micro \
  --subnet=default \
  --network-tier=PREMIUM \
  --maintenance-policy=MIGRATE \
  --tags=http-server,https-server grpc-server\
  --image=ubuntu-1804-bionic-v20190307 \
  --image-project=ubuntu-os-cloud \
  --boot-disk-size=10GB \
  --boot-disk-type=pd-standard \
  --boot-disk-device-name=grpc-test-vm  
```
2. Configure your firewall rules

```
gcloud compute --project=grpc-field-test firewall-rules create default-allow-http \
--direction=INGRESS \
--priority=1000 \
--network=default \
--action=ALLOW \
--rules=tcp:80 \
--source-ranges=0.0.0.0/0 \
--target-tags=http-server

gcloud compute --project=grpc-field-test firewall-rules create default-allow-https \
--direction=INGRESS \
--priority=1000 \
--network=default \
--action=ALLOW \
--rules=tcp:443 \
--source-ranges=0.0.0.0/0 \
--target-tags=https-server

gcloud compute --project=grpc-field-test firewall-rules create default-allow-grpc \
--direction=INGRESS \
--priority=1000 \
--network=default \
--action=ALLOW \
--rules=tcp:50000 \
--source-ranges=0.0.0.0/0 \
--target-tags=https-server
```

3. Get your VM ready

We will need to install the following:
- Docker
- certbot (needed later to get the Letsencrypt certificates for the TLS part)

For convienience there is a shell script in this repository which will do all teh steps for you.

```
# copy the script to your VM:
gcloud compute scp ./vm-setup  grpc-test-vm:~/vm-setup --recurse

# connect to your VM:
gcloud compute ssh grpc-test-vm

# make your shell script executable
chmod +x vm-setup/*.sh

# run the script
cd vm-setup && ./vm-setup.sh
```

4. Create a network bridge in Docker in your VM
```
sudo docker network create --driver bridge esp_net
```

5. Start your YAGES GRPC echo server on your VM
```
sudo docker run \
    --detach \
    -p 9000:9000 \
    --name=yages \
    --net=esp_net \
    quay.io/mhausenblas/yages:0.1.0
```


6. Deploy your Google Cloud endpoints API



7. Start the ESP on your VM

```
sudo docker run \
    --detach \
    --name=esp \
    --publish=50000:9000 \
    --net=esp_net \
    gcr.io/endpoints-release/endpoints-runtime:1 \
    --service=SERVICE_NAME \
    --rollout_strategy=managed \
    --http2_port=50000 \
    --backend=grpc://YOUR_API_CONTAINER_NAME:9000
```


Congratulations! You have a running GRPC service with Google Cloud endpoints.
Do a quick test with GRPCURL.

On your local machine, run:
```
docker run --name grpcclient --rm -it quay.io/mhausenblas/gump:0.1 sh

# inside the container
grpcurl --plaintext [your-service-url]:50000 yages.Echo.Ping
```







## Verdict on Google Cloud & GRPC

## Further Reading
https://cloud.google.com/endpoints/docs/grpc/get-started-compute-engine-docker
https://cloud.google.com/endpoints/docs/grpc/specify-proxy-startup-options
https://cloud.google.com/endpoints/docs/grpc/enabling-ssl

