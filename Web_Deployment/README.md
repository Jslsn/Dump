# Jordan's basic Web Deployment

This is a basic site, I've designed it with availability, fault tolerance, and security in mind. Redeployability and making it something that can be easily modified for said redeployments are also things I've taken into consideration.

## Versions

There are two versions of this deployment, one is more secure as it forces https traffic, one is less so as it goes through http.


## Deploment
These versions have different requirements, so each terraform directory will have it's own instructions.


### Docker
This deployment uses docker to run the website on the instances, this was done to make the site somewhat more customisable for redeployments.

Running both deployments plain should give you a simple site I threw together by pulling a pre-built and pushed image, but if you wish to make your own you can edit the files as stated in the docker directory.
