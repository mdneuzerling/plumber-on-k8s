# Plumber on Kubernetes

This is the Dockerfile and YAML files behind my blog post, [Hosting a Plumber API with Kubernetes](https://mdneuzerling.com/post/hosting-a-plumber-api-with-kubernetes/).

## The basic architecture of Kubernetes
### Understand the container

The central concept of Kubernetes is the _container_. When I have an application that I want to deploy, I can bundle it up together with the software that it requires to run into a single blob called a container. That container can then be run on another machine that doesn't have the application or its dependencies installed. The _Rocker_ project, for example, provides containers with R or RStudio and all of their dependencies. I can run that container on another machine and access R or RStudio, without actually installing R or RStudio. The most common software for creating and running containers is called _Docker_.

Containers solve a lot of problems. I can bundle up an R script with the exact versions of the packages it uses to have a reproducible analysis. I can turn my R script into an API with `plumber` and put that in a container, so that running the container hosts the API. I can run multiple containers on the same machine, even if the applications are unrelated. If one of my applications requires version 3.6 of R, and another requires 4.0, then they can run side-by-side in containers.

### Now run 100 containers

There's complexity involved with running many containers, and it's this complexity Kubernetes targets. I provide Kubernetes with a description of what I want the system to look like. I might ask for "3 copies of container A, and 2 copies of container B at all times" and Kubernetes will do its best to make that a reality.

Kubernetes is almost always run on a _cluster_ of multiple machines. It can run copies of the same container (_replicas_) across multiple machines so that they can share a computational load, or so that if one falls over there's another container ready to pick up the slack. In fact, Kubernetes doesn't consider containers precious; they're treated as ephemeral and replaceable. This also makes it easier to scale if there's a spike in demand: just add more containers!^[I count at least three different ways to scale with Kubernetes. Adding more containers is just an example.]

It's not as simple as Kubernetes running containers, though. There are a few layers in between.

A _node_ is a machine. It can be a Raspberry Pi, an old laptop, or a server with a six-figure price tag. Or it can be a virtual machine like an AWS EC2 instance.

At least one of these nodes is special. It contains the _control plane_^[The deprecated term for the node with the control plane is the _master_ node. This is the only time I will refer to the node with this terminology.], and it's what coordinates the containers. The other nodes are called _worker_ nodes, and it's on these nodes that the containers are run.

There's another layer in between node and container, and it's the _pod_. Containers are grouped together in pods. Containers that rely on each other to perform a common goal are configured by the user to run in a pod together. A simple container that doesn't rely on anything else can run in a pod by itself. In practice, the user configures pods, not containers.

![](https://mdneuzerling.com/post/hosting-a-plumber-api-with-kubernetes/nodes.png)

## File description

### Creating the API

The Plumber API itself consists of two files:

* `plumber.R` implements some basic functions as API endpoints:
    * `/parity` determines if a given integer is odd or even
    * `/wait` waits 5 seconds, then returns the current time as a nicely formatted string
    * `/fail` sets the `alive` global variable to `FALSE`.
    * `/quit` runs `quit()`, exiting the R process that runs the API.
    * `/health` returns "OK" if the `alive` global variable is `TRUE`, and throws an error otherwise.
* `entrypoint.R` loads the dependencies and runs the plumber API. It can be called from shell with `Rscript entrypoint.R`

### Creating the Docker image

The `Dockerfile` is used to build a Docker image that runs `entrypoint.R` and exposes the API on port 8000. The Docker image can be built with:
```
docker build -t mdneuzerling/plumber-on-k8s <directory-with-files>
```
and the resulting image run with:
```
docker run -p 8000:8000 mdneuzerling/plumber-on-k8s
```
The image can be hosted on a container registry, such as Docker Hub.

### Deploying the API

Kubernetes is often configured with YAML files. These describe a desired state which the Kubernetes cluster will work towards making a reality. This API requires a _deployment_, a _service_, and an _ingress_:

* After making the above image available on Docker Hub, `deployment.yaml` configures a deployment on a Kubernetes cluster with 3 replicas of the image. It also configures liveness and readiness probes using the `/health` endpoint.
* `service.yaml` implements a service to port 8000 of the pods in the deployment.
* `ingress.yaml` exposes the service to the outside world, so that the API can be queried. For a local deployment inside a home network, the availability of the API will depend on firewall settings.

These YAML files can be applied with `kubectl`:
```
kubectl apply -f https://raw.githubusercontent.com/mdneuzerling/plumber-on-k8s/main/deployment.yaml
```
