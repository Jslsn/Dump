# Docker used for the Web Deployment

This is what's used to create the image for the containers that the instances run.

If you want to launch your own version of the site on this same architecture:

- Update the index.html as you please.

- Run a docker build and push it to a public repository.

- Update the init.sh to pull and run your container by entering your full image tag on line 2.
