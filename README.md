Travis-CI scripts
=================

## Dockerfile
Build arguments within Dockerfiles should always have a default value.

## Build process
1) Activate the master branch build on Docker Hub. Set the tag to 'temporary'. This ensures that on each update of the master branch the readme and Dockerfile on Docker Hub are updated.

2) Build using Travis. Download generic build script from `roeldev/travis-ci-scripts`. Perform build + push tags to Docker Hub. Remove image with 'temporary' tag from Docker Hub.

## License
[GPL-3.0+](LICENSE) © 2019 [Roel Schut](https://roelschut.nl)
