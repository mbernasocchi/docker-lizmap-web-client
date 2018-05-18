# 
# Build docker image
#
#

NAME=lizmap-wps-web-client

BUILDID=$(shell date +"%Y%m%d%H%M")
COMMITID=$(shell git rev-parse --short HEAD)

VERSION=3.2pre
VERSION_SHORT=3.2

VERSION_TAG=$(VERSION)

LIZMAP_BRANCH:=release_3_2
LIZMAP_WPS_BRANCH:=master

BUILD_ARGS=--build-arg lizmap_version=$(LIZMAP_BRANCH) \
--build-arg lizmap_wps_version=$(LIZMAP_WPS_BRANCH)

ifdef REGISTRY_URL
REGISTRY_PREFIX=$(REGISTRY_URL)/
BUILD_ARGS += --build-arg REGISTRY_PREFIX=$(REGISTRY_PREFIX)
endif

BUILDIMAGE=$(NAME):$(VERSION_TAG)-$(COMMITID)
ARCHIVENAME=$(shell echo $(NAME):$(VERSION_TAG)|tr '[:./]' '_')

MANIFEST=factory.manifest

all:
	@echo "Usage: make [build|archive|deliver|clean]"

manifest:
	echo name=$(NAME) > $(MANIFEST) && \
    echo version=$(VERSION)   >> $(MANIFEST) && \
    echo version_short=$(VERSION_SHORT) >> $(MANIFEST) && \
    echo buildid=$(BUILDID)   >> $(MANIFEST) && \
    echo commitid=$(COMMITID) >> $(MANIFEST) && \
    echo archive=$(ARCHIVENAME) >> $(MANIFEST)

build: manifest
	docker build --rm --force-rm --no-cache $(BUILD_ARGS) -t $(BUILDIMAGE) .

test:
	@echo No tests defined !

archive:
	docker save $(BUILDIMAGE) | bzip2 > $(FACTORY_ARCHIVE_PATH)/$(ARCHIVENAME).bz2

deliver:
	docker tag $(BUILDIMAGE) $(REGISTRY_URL)/$(NAME):latest
	docker tag $(BUILDIMAGE) $(REGISTRY_URL)/$(NAME):$(VERSION)
	docker tag $(BUILDIMAGE) $(REGISTRY_URL)/$(NAME):$(VERSION_SHORT)
	docker push $(REGISTRY_URL)/$(NAME):latest
	docker push $(REGISTRY_URL)/$(NAME):$(VERSION)
	docker push $(REGISTRY_URL)/$(NAME):$(VERSION_SHORT)

clean:
	docker rmi -f $(shell docker images $(BUILDIMAGE) -q)
   
LIZMAP_USER:=$(shell id -u)

run:
	rm -rf $(shell pwd)/.run
	docker run -it --rm -p 9000:9000 \
    -v $(shell pwd)/.run/config:/www/lizmap/var/config \
    -v $(shell pwd)/.run/web:/www/lizmap/www \
    -v $(shell pwd)/.run/log:/usr/local/var/log \
    -v $(shell pwd)/.run/lizmap-theme-config:/www/lizmap/var/lizmap-theme-config \
    -e LIZMAP_WMSSERVERURL=$(LIZMAP_WMSSERVERURL) \
    -e LIZMAP_CACHEREDISHOST=$(ILZMAP_CACHEREDISHOST) \
    -e LIZMAP_USER=$(LIZMAP_USER) \
    $(BUILDIMAGE) php-fpm
