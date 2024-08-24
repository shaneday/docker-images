This repo contains a set of Dockerfiles for building minimal, clean images, inspired by challenges I faced working with currently available images.

## Motivation

I can't explain much better than I did in the original rant email to my colleagues.

    <rant>
    I'm somewhat disappointed with the state of dockerhub base images. If you try to trace the source Dockerfile instructions, many of these contain completely obscene sequences of commands and often resort to untar'ing some large pre-prepared archive fetched from some download site, or some .tar.xz that is committed beside the Dockerfile, or hard coded download URLs becoming stale, or 3rd party apt repos with expired keys etc, often resulting in images that are amd64 only. 🤦‍♂️
    
    So, in my own time,  I'm considering getting my head around cleanly tying GitHub repos with GitHub Actions to build and push to DockerHub, without any obscure 'curl | tar' rubbish. (since I should know these systems better anyway)
    
    I've had this exact same problem when dealing with my video tools at home (on M2 cpu) and Kubernetes images. "Just trust our *trusted* dockerhub image that we build by downloading everything from random sites". To which the suggested solution seems to be to use version specific tags rather than :latest, implying you shouldn't trust :latest!
    </rant>


## Issues I've encountered

- **Fragility**. Dockerfiles working one day and failing the next. Because they pull stuff off the internet that has changed or expired, often using URLs containing hardcoded app version numbers, or using old OS releases that have migrated off the Debian mirrors, or 3rd party repos that have stopped working or have expired keys.

- **Nontransparency**. RUN command lines so complex I can't tell what they do, or that download and unpack tar files, or worse, that download and run bash scripts.

- **Nonportability**. Many Dockerhub images don't provide ARM builds.

- **Bloat**. Many images are much larger than necessary, although people seem to be getting better at reducing them. Our MySQL is 1GB. And given the layering way images work, you can't remove junk in later layers.

- **Security**. Reducing bloat also reduces the attack surface. Taken to the extreme, an image that doesn't even contain bash is much harder for a hacker to mess around with than one with all the standard cmdline tools. Having cmdline tools inside a container is a security concern since if the packaged app has a vulnerability and an attacker manages to perform a code execution exploit on the exposed app (via buffer overflow etc), the first thing they are likely to do is to try and get access to a shell (inside the container). From there they can poke around and try to find an exploit to escape out of the container to gain access to the host. But not many images go the this extreme, since it makes it rather difficult to debug things when you can't "docker exec -it appname bash".


## Requirements

After initial investigation, it looks like I have a unique set of requirements. There are *reproducible build* efforts for both building bit-for-bit identical Debian dpkg binaries and similar for docker images. However, both aim to build old images again and get identical results.

I'm more interested in having:
- Easily readable sequences of Dockerfile RUN commands.
- No fetching and unpacking opaque tarballs. They just feel scary and are often single architecture.
- New image builds triggered only when upstream packages are updated, rather than on some arbitrary weekly/monthly schedule.
- Multi-arch. At least amd64 & arm64, but also 32-bit when possible, for small systems like my NAS or Raspberry Pi.
- At least initially, Debian-based, but only because that's what I'm most familiar with. Alpine is likely to be of interest as it allows reducing the attack surface.
- It would be nice to be able to reproduce bit-for-bit, but it is not critical, and from looking at existing solutions, this is likely to be counter to my first requirement.
- No build instructions necessary. Just run 'make'.

Since I need to detect when a new build should be done, I need to collect a list of installed package versions and be able to check each for new version availability. Initially, this could be done by rebuilding daily and discarding the result if package versions are unchanged, but I should be able to grep Debian package list files to do this check efficiently.  Building itself will need to be done as a multi-stage build, that is, creating a *builder* image, and then using debootstrap to do a fresh minimal OS install into a directory, that can then be copied into a *scratch (empty)* Docker image. Debootstrap builds the root-filesystem by fetching and unpacking the core set of .dpkg files. The current offical Debian base docker image is built by unpacking a tar.xz that has been committed to the git repo, yikes. Once I have a minimal image, I can build on that to create a heavy image with all the usual tools like compilers and devops commands. Then I can add application images, following the same above requirements. In the easy case this will be a few apt-get install and config files. In the hard case this will be git-clone and build from source in multi-stage Dockerfiles.

I'm still somewhat undecided if application images should include useful devops commands. Security best-practice is to include only what is required for the app to run. Go and Rust images can often be created with only a single file in the image. Kubernetes allows devops to attach tool packed images to running Pods, but in Docker it's probably more important to have all the tools we need already available in the containers. Maybe I just need fat and thin versions of each app image.
