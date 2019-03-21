# Activate TLS for your GRPC service

Google Cloud currently only provides a Certificate Management Service for their load balancers and it will stay in BETA at least until end of 2019. (see https://cloud.google.com/load-balancing/docs/ssl-certificates#managed-certs).

For this tutorial we choose to use [Let's Encrypt](https://letsencrypt.org/).

## Before we begin

You should have completed the [basic tutorial](../README.md) which means that you have:
- your Google Cloud project
- a running Google Compute Engine instance
- your GRPC service and an instance of Google's ESP running as docker container on your VM
- Cloud Endpoints configured for your API

## Let's get started

First connect to your VM.
```
gcloud compute ssh [INSTANCE NAME]

### Example:
gcloud compute ssh grpc-test-vm
```

On your VM you should already have certbot installed if you followed the basic tutorial.
Otherwise install certbot and it's nginx plugin by running:
```
sudo apt update
sudo apt install certbot python-certbot-nginx -y
```

Now we can generate our Let's Encrypt Certificate.

```
sudo certbot --nginx certonly -d [YOUR ENDPOINTS DOMAIN]

### Example
sudo certbot --nginx certonly -d echo.endpoints.grpc-endpoints-test-234608.cloud.goog
```

Follow the dialog on the screen and you will get your certificate your VM.
Now we need to provide the certificate to the ESP.

Stop and remove your running ESP for now:
```
sudo docker stop [ESP CONTAINER NAME]
sudo docker rm [ESP CONTAINER NAME]

### Example
sudo docker stop esp
sudo docker rm esp
```

Then create it again with TLS support:
```
sudo docker run --name=esp \
     --detach \
     --publish=443:443 \
     --net=esp_net \
     --volume=[PATH TO CERT FILE]:/etc/nginx/ssl/nginx.cert \
     --volume=[PATH TO KEY FILE]:/etc/nginx/ssl/nginx.key \
     --link=[GRPC SERVICE CONTAINER NAME]:[GRPC SERVICE CONTAINER NAME] \
     gcr.io/endpoints-release/endpoints-runtime:1.30.0 \
     --service=[SERVICE_NAME] \
     --rollout_strategy=managed \
     --backend=[GRPC SERVICE CONTAINER NAME]:8080 \
     --ssl_port=443

### Example
sudo docker run --name=esp \
     --detach \
     --publish=443:443 \
     --net=esp_net \
     --volume=/etc/letsencrypt/live/echo.endpoints.grpc-endpoints-test-234608.cloud.goog/privkey.pem:/etc/nginx/ssl/nginx.key \
     --volume=/etc/letsencrypt/live/echo.endpoints.grpc-endpoints-test-234608.cloud.goog/cert.pem:/etc/nginx/ssl/nginx.crt \
     --link=yages:yages \
     gcr.io/endpoints-release/endpoints-runtime:1.30.0 \
     --service=echo.endpoints.grpc-endpoints-test-234608.cloud.goog \
     --rollout_strategy=managed \
     --backend=yages:9000 \
     --ssl_port=443
```

__Important!__
The ESP runtime container expects the certificated files to be named nginx.crt and nginx.key
> For HTTPS connections, ESP expects the TLS secrets to be located at /etc/nginx/ssl/nginx.crt and /etc/nginx/ssl/nginx.key.
Source: https://cloud.google.com/endpoints/docs/openapi/specify-proxy-startup-options

What we changed:
- the ESP now listens on the SSL port 443
- we mounted the certificate files on our host into the container
- 




### Further reading
- https://cloud.google.com/endpoints/docs/grpc/enabling-ssl  
- https://certbot.eff.org/lets-encrypt/ubuntubionic-nginx.html  