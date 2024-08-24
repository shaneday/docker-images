.PHONY: all build-debian

# All available platforms for Debian. Probably overkill, consider reducing.
PLATFORMS = linux/386,linux/amd64,linux/arm/v5,linux/arm/v7,linux/arm64/v8,linux/mips64le,linux/ppc64le,linux/s390x
NAMESPACE = shaneday

all: build-debian

build-debian:
	# Build the Debian image for all platforms
	docker buildx build --platform $(PLATFORMS) -t $(NAMESPACE)/debian:12 --load ./debian/

	# Gather data from the images
	docker run -it --rm $(NAMESPACE)/debian:12 bash -c 'du -kx . | sort -n' > debian-sizes.txt
	docker image ls $(NAMESPACE)/debian:12 >> debian-sizes.txt
	# TODO: Gather list of installed packages and versions
