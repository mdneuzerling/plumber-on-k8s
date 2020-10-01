FROM rocker/r-ver:4.0.0

RUN apt-get update -qq && apt-get -y --no-install-recommends install \
	make \
	libsodium-dev \
	libicu-dev \
	libcurl4-openssl-dev \
	libssl-dev

RUN install2.r plumber promises future

# Create a non-root plumber user to run the API
RUN useradd plumber \
	&& mkdir /home/plumber \
	&& chown plumber:plumber /home/plumber

ADD plumber.R /home/plumber/plumber.R
ADD entrypoint.R /home/plumber/entrypoint.R

EXPOSE 8000

WORKDIR /home/plumber
CMD su - plumber -c "Rscript entrypoint.R"