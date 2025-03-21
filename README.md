# ⛵ Home Kubernetes

This my implementation of a home Kubernetes cluster based on Talos Linux.  It was templated from  [cluster-template](https://github.com/onedr0p/cluster-template) by [onedr0p](https://github.com/onedr0p).

## ✨ Features

The stack includes:

- [Talos Linux](https://github.com/siderolabs/talos) - base OS (Talos' documentation is utter trash, by the way)
- [Flux](https://github.com/fluxcd/flux2) - GitOps
- [GitHub](https://github.com/) - Git repo
- [sops](https://github.com/getsops/sops) - Local secrets management
- [Cilium](https://github.com/cilium/cilium) - Networking
- [cert-manager](https://github.com/cert-manager/cert-manager) - Automatic certificate provisioning
- [spegel](https://github.com/spegel-org/spegel) - Cluster local OCI registry mirror
- [reloader](https://github.com/stakater/Reloader) - Watches changes in ConfigMaps or Secrets and does rolling upgrades on Pods
- [ingress-nginx](https://github.com/kubernetes/ingress-nginx/) - Ingress controller
- [external-dns](https://github.com/kubernetes-sigs/external-dns) - External DNS for exposed services
- [cloudflared](https://github.com/cloudflare/cloudflared) - Manages [Cloudflare](https://www.cloudflare.com/) [Tunnel](https://www.cloudflare.com/products/tunnel/)
- [Renovate](https://www.mend.io/renovate) - Generates PRs for updatates
- ~~[Longhorn](https://longhorn.io/) - Distributed storage (not awesome, but it does the trick, given my crusty, old hardware)~~
- [Rook-Ceph](https://rook.io/) - Distributed storage (seemingly working better now that I don't have failing disks?)
- [OpenEBS](https://openebs.io/) - This is/was configured by default from the cluster-template. I chose to replace it with Longhorn (for better or worse)

## 💻 Hardware

The hardware this runs on is a mix of 12th and 13th gen crusty, old 2U pizza-boxes from Dell and IBM.  There's also another crusty, old 2U Dell that serves as a NAS for all this.

Each node has _some_ "extra" storage that is used by Rook.  It's nothing special, and honestly, probably the biggest hinderance to this being a "decent" cluster.  But...storage is expensive.

## 🚀 Getting Started

(Leaving this all here for posterity, since I _know_ I'm going to have to start all over again at some point.)

### Installing Talos

You don't so much "install" Talos, as you just boot an ISO and when you run `task talos:bootstrap` (later), it will "just work".

That's not ot say that you don't have to do SOME preparation, specifically, you need to make sure the nodes have their networking "right".  This might involve setting static DHCP reservations, or using a Talos ISO SPECIFIC to the node that you're working on, with the [appropriate kernel parameters set](https://www.talos.dev/v1.7/talos-guides/install/bare-metal-platforms/network-config/).

Once you have installed Talos on your nodes, there are six stages to getting a Flux-managed cluster up and runnning.

> [!NOTE]
> For all stages below the commands **MUST** be ran on your personal workstation within your repository directory

### 🎉 Stage 1: Create a Git repository

1. Create a new **public** repository by clicking the big green "Use this template" button at the top of this page.

2. Clone **your new repo** to you local workstation and `cd` into it.

3. Continue on to 🌱 [**Stage 2**](#-stage-2-setup-your-local-workstation-environment)

### 🌱 Stage 2: Setup your local workstation

You have two different options for setting up your local workstation.

- First option is using a `devcontainer` which requires you to have Docker and VSCode installed. This method is the fastest to get going because all the required CLI tools are provided for you in my [devcontainer](https://github.com/onedr0p/cluster-template/pkgs/container/cluster-template%2Fdevcontainer) image.
- The second option is setting up the CLI tools directly on your workstation.

#### Devcontainer method

1. Start Docker and open your repository in VSCode. There will be a pop-up asking you to use the `devcontainer`, click the button to start using it.

2. Continue on to 🔧 [**Stage 3**](#-stage-3-bootstrap-configuration)

#### Non-devcontainer method

> [!NOTE]
> Honestly, don't even bother with this, because it's kinda hit or miss

1. Install the most recent version of [task](https://taskfile.dev/), see the [installation docs](https://taskfile.dev/installation/) for other supported platforms.

    ```sh
    # Homebrew
    brew install go-task
    # or, Arch
    pacman -S --noconfirm go-task && ln -sf /usr/bin/go-task /usr/local/bin/task
    ```

2. Install the most recent version of [direnv](https://direnv.net/), see the [installation docs](https://direnv.net/docs/installation.html) for other supported platforms.

    ```sh
    # Homebrew
    brew install direnv
    # or, Arch
    pacman -S --noconfirm direnv
    ```

3. [Hook `direnv` into your preferred shell](https://direnv.net/docs/hook.html), then run:

    ```sh
    task workstation:direnv
    ```

    📍 _**Verify** that `direnv` is setup properly by opening a new terminal and `cd`ing into your repository. You should see something like:_

    ```sh
    cd /path/to/repo
    direnv: loading /path/to/repo/.envrc
    direnv: export +ANSIBLE_COLLECTIONS_PATH ...  +VIRTUAL_ENV ~PATH
    ```

4. Install the additional **required** CLI tools

   📍 _**Not using Homebrew or ArchLinux?** Try using the generic Linux task below, if that fails check out the [Brewfile](.taskfiles/Workstation/Brewfile)/[Archfile](.taskfiles/Workstation/Archfile) for what CLI tools needed and install them._

    ```sh
    # Homebrew
    task workstation:brew
    # or, Arch with yay/paru
    task workstation:arch
    # or, Generic Linux (YMMV, this pulls binaires in to ./bin)
    task workstation:generic-linux
    ```

5. Setup a Python virual environment by running the following task command.

    📍 _This commands requires Python 3.11+ to be installed._

    ```sh
    task workstation:venv
    ```

6. Continue on to 🔧 [**Stage 3**](#-stage-3-bootstrap-configuration)

### 🔧 Stage 3: Bootstrap configuration

> [!NOTE]
> The [config.sample.yaml](./config.sample.yaml) file contains config that is **vital** to the bootstrap process.

1. Generate the `config.yaml` from the [config.sample.yaml](./config.sample.yaml) configuration file.

    ```sh
    task init
    ```

2. Fill out the `config.yaml` configuration file using the comments in that file as a guide.

3. Run the following command which will generate all the files needed to continue.

    ```sh
    task configure
    ```

> [!NOTE]
> At this point you may want to take long, hard look at the things that were actually written.  Specifically, you may want to [provision additional storage](https://kubito.dev/posts/talos-linux-additonal-disks-to-nodes/) at this time.

4. Push your changes to git

   📍 _**Verify** all the `./kubernetes/**/*.sops.*` files are **encrypted** with SOPS_

    ```sh
    git add -A
    git commit -m "Initial commit :rocket:"
    git push
    ```

### ⛵ Stage 4: Install Kubernetes

1. Deploy your cluster and bootstrap it. This generates secrets, generates the config files for your nodes and applies them. It bootstraps the cluster afterwards, fetches the kubeconfig file and installs Cilium and kubelet-csr-approver. It finishes with some health checks.

    ```sh
    task talos:bootstrap
    ```

2. ⚠️ It might take a while for the cluster to be setup (10+ minutes is normal), during which time you will see a variety of error messages like: "couldn't get current server API group list," "error: no matching resources found", etc. This is a normal. If this step gets interrupted, e.g. by pressing <kbd>Ctrl</kbd> + <kbd>C</kbd>, you likely will need to [nuke the cluster](#-Nuke) before trying again.

#### Cluster validation

1. The `kubeconfig` for interacting with your cluster should have been created in the root of your repository.

2. Verify the nodes are online

    📍 _If this command **fails** you likely haven't configured `direnv` as [mentioned previously](#non-devcontainer-method) in the guide._

    ```sh
    kubectl get nodes -o wide
    NAME           STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE         KERNEL-VERSION   CONTAINER-RUNTIME
    kubernetes-0   Ready    control-plane   11h   v1.30.3   10.100.50.100   <none>        Talos (v1.7.6)   6.6.43-talos     containerd://1.7.18
    kubernetes-1   Ready    control-plane   11h   v1.30.3   10.100.50.101   <none>        Talos (v1.7.6)   6.6.43-talos     containerd://1.7.18
    kubernetes-2   Ready    control-plane   11h   v1.30.3   10.100.50.102   <none>        Talos (v1.7.6)   6.6.43-talos     containerd://1.7.18
    ```

3. Continue on to 🔹 [**Stage 6**](#-stage-6-install-flux-in-your-cluster)

### 🔹 Stage 6: Install Flux in your cluster

1. Verify Flux can be installed

    ```sh
    flux check --pre
    # ► checking prerequisites
    # ✔ kubectl 1.30.1 >=1.18.0-0
    # ✔ Kubernetes 1.30.1 >=1.16.0-0
    # ✔ prerequisites checks passed
    ```

2. Install Flux and sync the cluster to the Git repository

    📍 _Run `task flux:github-deploy-key` first if using a private repository._

    ```sh
    task flux:bootstrap
    # namespace/flux-system configured
    # customresourcedefinition.apiextensions.k8s.io/alerts.notification.toolkit.fluxcd.io created
    # ...
    ```

1. Verify Flux components are running in the cluster

    ```sh
    kubectl -n flux-system get pods -o wide
    # NAME                                       READY   STATUS    RESTARTS   AGE
    # helm-controller-5bbd94c75-89sb4            1/1     Running   0          1h
    # kustomize-controller-7b67b6b77d-nqc67      1/1     Running   0          1h
    # notification-controller-7c46575844-k4bvr   1/1     Running   0          1h
    # source-controller-7d6875bcb4-zqw9f         1/1     Running   0          1h
    ```

### 🎤 Verification Steps

_Mic check, 1, 2_ - In a few moments applications should be lighting up like Christmas in July 🎄

1. Output all the common resources in your cluster.

    📍 _Feel free to use the provided [kubernetes tasks](.taskfiles/Kubernetes/Taskfile.yaml) for validation of cluster resources or continue to get familiar with the `kubectl` and `flux` CLI tools._

    ```sh
    task kubernetes:resources
    ```

2. ⚠️ It might take `cert-manager` awhile to generate certificates, this is normal so be patient.

3. 🏆 **Congratulations** if all goes smooth you will have a Kubernetes cluster managed by Flux and your Git repository is driving the state of your cluster.

4. 🧠 Now it's time to pause and go get some motel motor oil ☕ and admire you made it this far!

## 📣 Flux w/ Cloudflare post installation

#### 🌐 Public DNS

The `external-dns` application created in the `networking` namespace will handle creating public DNS records. By default, `echo-server` and the `flux-webhook` are the only subdomains reachable from the public internet. In order to make additional applications public you must set set the correct ingress class name and ingress annotations like in the HelmRelease for `echo-server`.

#### 🏠 Home DNS

`k8s_gateway` will provide DNS resolution to external Kubernetes resources (i.e. points of entry to the cluster) from any device that uses your home DNS server. For this to work, your home DNS server must be configured to forward DNS queries for `${bootstrap_cloudflare.domain}` to `${bootstrap_cloudflare.gateway_vip}` instead of the upstream DNS server(s) it normally uses. This is a form of **split DNS** (aka split-horizon DNS / conditional forwarding).

I'm running AdGuard Home for my "main" network's DNS server.  In order to get DNS working appropriately using split DNS, you have to set up a conditional forwarder to the gateway VIP, it will look something like this:

```
[/example.com/]192.168.1.150
```

This is assuming the domain name you're using is example.com, and your gateway VIP is at 192.168.1.150.  If that's the case you'd add that line to your "Upstream DNS servers" in your AdGuard Home DNS settings.  This has worked just fine for me.

DNS is almost always the problem...and it took me a long time to get it sorted.

<!-- #### 📜 Certificates

By default this template will deploy a wildcard certificate using the Let's Encrypt **staging environment**, which prevents you from getting rate-limited by the Let's Encrypt production servers if your cluster doesn't deploy properly (for example due to a misconfiguration). Once you are sure you will keep the cluster up for more than a few hours be sure to switch to the production servers as outlined in `config.yaml`.

📍 _You will need a production certificate to reach internet-exposed applications through `cloudflared`._ -->

#### 🪝 Github Webhook

By default Flux will periodically check your git repository for changes. In order to have Flux reconcile on `git push` you must configure Github to send `push` events to Flux.

> [!NOTE]
> This will only work after you have switched over certificates to the Let's Encrypt Production servers.

1. Obtain the webhook path

    📍 _Hook id and path should look like `/hook/12ebd1e363c641dc3c2e430ecf3cee2b3c7a5ac9e1234506f6f5f3ce1230e123`_

    ```sh
    kubectl -n flux-system get receiver github-receiver -o jsonpath='{.status.webhookPath}'
    ```

2. Piece together the full URL with the webhook path appended

    ```text
    https://flux-webhook.${bootstrap_cloudflare.domain}/hook/12ebd1e363c641dc3c2e430ecf3cee2b3c7a5ac9e1234506f6f5f3ce1230e123
    ```

3. Navigate to the settings of your repository on Github, under "Settings/Webhooks" press the "Add webhook" button. Fill in the webhook URL and your `bootstrap_github_webhook_token` secret in `config.yaml`, Content type: `application/json`, Events: Choose Just the push event, and save.

## 💥 Nuke

There might be a situation where you want to destroy your Kubernetes cluster. The following command will reset your nodes back to maintenance mode, append `--force` to completely format your the Talos installation. Either way the nodes should reboot after the command has run.

```sh
task talos:nuke
```

## 🤖 Renovate

[Renovate](https://www.mend.io/renovate) is a tool that automates dependency management. It is designed to scan your repository around the clock and open PRs for out-of-date dependencies it finds. Common dependencies it can discover are Helm charts, container images, GitHub Actions, Ansible roles... even Flux itself! Merging a PR will cause Flux to apply the update to your cluster.

To enable Renovate, click the 'Configure' button over at their [Github app page](https://github.com/apps/renovate) and select your repository. Renovate creates a "Dependency Dashboard" as an issue in your repository, giving an overview of the status of all updates. The dashboard has interactive checkboxes that let you do things like advance scheduling or reattempt update PRs you closed without merging.

The base Renovate configuration in your repository can be viewed at [.github/renovate.json5](./.github/renovate.json5). By default it is scheduled to be active with PRs every weekend, but you can [change the schedule to anything you want](https://docs.renovatebot.com/presets-schedule), or remove it if you want Renovate to open PRs right away.

## 🐛 Debugging

Below is a general guide on trying to debug an issue with an resource or application. For example, if a workload/resource is not showing up or a pod has started but in a `CrashLoopBackOff` or `Pending` state.

1. Start by checking all Flux Kustomizations & Git Repository & OCI Repository and verify they are healthy.

    ```sh
    flux get sources oci -A
    flux get sources git -A
    flux get ks -A
    ```

2. Then check all the Flux Helm Releases and verify they are healthy.

    ```sh
    flux get hr -A
    ```

3. Then check the if the pod is present.

    ```sh
    kubectl -n <namespace> get pods -o wide
    ```

4. Then check the logs of the pod if its there.

    ```sh
    kubectl -n <namespace> logs <pod-name> -f
    # or
    stern -n <namespace> <fuzzy-name>
    ```

5. If a resource exists try to describe it to see what problems it might have.

    ```sh
    kubectl -n <namespace> describe <resource> <name>
    ```

6. Check the namespace events

    ```sh
    kubectl -n <namespace> get events --sort-by='.metadata.creationTimestamp'
    ```

Resolving problems that you have could take some tweaking of your YAML manifests in order to get things working, other times it could be a external factor like permissions on NFS. If you are unable to figure out your problem see the help section below.

## ⬆️ Upgrading Talos and Kubernetes

### Manual

```sh
# Upgrade Talos to a newer version
# NOTE: This needs to be run once on every node
talosctl upgrade -n <IP_address> --preserve=true --wait=false --image factory.talos.dev/installer/032aa44d3c16e7761d33a941957477ca0fb279f4c5d13d1ef568de0636464e57:v1.9.2
# e.g.
# task talos:upgrade node=192.168.42.10 image=factory.talos.dev/installer/${schematic_id}:v1.7.4
```

```sh
# Upgrade Kubernetes to a newer version
# NOTE: This only needs to be run once against a controller node
task talos:upgrade-k8s controller=? to=?
# e.g.
# task talos:upgrade-k8s controller=192.168.42.10 to=1.30.1
```

## 👉 Help

- Make a post in this repository's Github [Discussions](https://github.com/onedr0p/cluster-template/discussions).
- Start a thread in the `#support` or `#cluster-template` channels in the [Home Operations](https://discord.gg/home-operations) Discord server.

<!-- ## ❔ What's next

The cluster is your oyster (or something like that). Below are some optional considerations you might want to review. -->

### Ship it

To browse or get ideas on applications people are running, community member [@whazor](https://github.com/whazor) created [Kubesearch](https://kubesearch.dev) as a creative way to search Flux HelmReleases across Github and Gitlab.

<!-- ### Storage

The included CSI (openebs in local-hostpath mode) is a great start for storage but soon you might find you need more features like replicated block storage, or to connect to a NFS/SMB/iSCSI server. If you need any of those features be sure to check out the projects like [rook-ceph](https://github.com/rook/rook), [longhorn](https://github.com/longhorn/longhorn), [openebs](https://github.com/openebs/openebs), [democratic-csi](https://github.com/democratic-csi/democratic-csi), [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs),
and [synology-csi](https://github.com/SynologyOpenSource/synology-csi). -->

## 🙌 Related Projects

If this repo is too hot to handle or too cold to hold check out these following projects.

- [khuedoan/homelab](https://github.com/khuedoan/homelab) - _Modern self-hosting framework, fully automated from empty disk to operating services with a single command._
- [danmanners/aws-argo-cluster-template](https://github.com/danmanners/aws-argo-cluster-template) - _A community opinionated template for deploying Kubernetes clusters on-prem and in AWS using Pulumi, SOPS, Sealed Secrets, GitHub Actions, Renovate, Cilium and more!_
- [ricsanfre/pi-cluster](https://github.com/ricsanfre/pi-cluster) - _Pi Kubernetes Cluster. Homelab kubernetes cluster automated with Ansible and ArgoCD_
- [techno-tim/k3s-ansible](https://github.com/techno-tim/k3s-ansible) - _The easiest way to bootstrap a self-hosted High Availability Kubernetes cluster. A fully automated HA k3s etcd install with kube-vip, MetalLB, and more_

<!--
## ⭐ Stargazers

<div align="center">

[![Star History Chart](https://api.star-history.com/svg?repos=onedr0p/cluster-template&type=Date)](https://star-history.com/#onedr0p/cluster-template&Date)

</div>

## 🤝 Thanks

Big shout out to all the contributors, sponsors and everyone else who has helped on this project. -->
