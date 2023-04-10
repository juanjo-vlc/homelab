# Deploying Nexus OSS on Kubernetes

Please take a look at the corresponding blog entry: https://juanjo.garciaamaya.com/posts/k8s/deploying-nexus-on-k8s/

For convenience, a Makefile has been added.
Basic operation:
1. Set your domain on the values file
2. Deploy Nexus
```sh
make deploy
```
3. Wait until nexus has boot
4. Store your new admin password in a the NXPWD variable and your domain name in NXDOMAIN
```sh
export NXPWD=supersecretpassword
export NXDOMAIN=nexus.my-domain.tld
```
5. Configure Nexus
```sh
make configure
```
