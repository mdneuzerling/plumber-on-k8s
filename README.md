# Plumber on Kubernetes

This is the Dockerfile and YAML files behind my blog post, [Hosting a Plumber API with Kubernetes](https://mdneuzerling.com/post/hosting-a-plumber-api-with-kubernetes/).

## File description

* `plumber.R` implements some basic functions as API endpoints:
    * `/parity` determines if a given integer is odd or even
    * `/wait` waits 5 seconds, then returns the current time as a nicely formatted string
    * `/fail` sets the `alive` global variable to `FALSE`.
    * `/quit` runs `quit()`, exiting the R process that runs the API.
    * `/health` returns "OK" if the `alive` global variable is `TRUE`, and throws an error otherwise.
* `entrypoint.R` loads the dependencies and runs the plumber API. It can be called from shell with `Rscript entrypoint.R`
* `Dockerfile` is used to build a Docker image that runs `entrypoint.R` and exposes the API on port 8000. The Docker image can be built with:
```
docker build -t mdneuzerling/plumber-on-k8s <directory-with-files>
```
and the resulting image run with:
```
docker run -p 8000:8000 mdneuzerling/plumber-on-k8s
```
* After making the above image available on Docker Hub, `deployment.yaml` configures a deployment on a Kubernetes cluster with 3 replicas of the image. It also configures liveness and readiness probes using the `/health` endpoint.
* `service.yaml` implements a service to port 8000 of the pods in the deployment.
* `ingress.yaml` exposes the service to the outside world, so that the API can be queried. For a local deployment inside a home network, the availability of the API will depend on firewall settings.
