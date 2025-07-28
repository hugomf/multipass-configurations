# Configuring Remote Docker Access from macOS to Multipass Ubuntu VM

This guide explains how to set up Docker on your macOS host to control a Docker daemon running inside a Multipass Ubuntu VM. This allows you to use the `docker` command locally while the containers run inside the VM.

## Prerequisites

1. Multipass installed on your macOS host.
2. Configure multipass **bridge** as follows:

    ```shell
    mp networks # check the wifi interface (usually it's en0
    mp set local.bridged-network=en0
    ```

3. Create an Ubuntu 24.04 VM with Docker installed:

    ```shell
    mp launch 24.04 \
    --name docker \
    --cpus 2 \
    --memory 4G \
    --disk 40G \
    --bridged \
    --cloud-init https://raw.githubusercontent.com/canonical/multipass/refs/heads/main/data/cloud-init-yaml/cloud-init-docker.yaml
    ```

4. Access to the instance: `multipass shell docker`.
5. Know the Local Network IP address of the Multipass VM (e.g., from `multipass list`).

## Insecure Connection (TCP port 2375)

**Warning:** This method sends data unencrypted. Use only on trusted networks.

### On the Multipass Ubuntu VM

1. **Modify Docker Daemon Configuration:**
    * Create or edit `/etc/docker/daemon.json`:

        ```bash
            sudo nano /etc/docker/daemon.json
        ```

    * Add the following content:

        ```json
        {
          "hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:2375"]
        }
        ```

    * Save and close the file.

2. **Configure the Docker Service:**
    * Override the default service configuration:

        ```bash
        sudo systemctl edit docker.service
        ```

    * Add these lines exactly:

        ```ini
        [Service]
        ExecStart=
        ExecStart=/usr/bin/dockerd
        ```

    * Save and close the file.

3. **Restart the Docker Service:**

    ```bash
    sudo systemctl daemon-reload
    sudo systemctl restart docker.service
    ```

4. **Verify the Port is Listening:**

    ```bash
    sudo netstat -tlnp | grep :2375
    # Or using ss:
    # sudo ss -tlnp | grep :2375
    ```

    You should see `dockerd` listening on `0.0.0.0:2375`.

### On your macOS Host

1. **Set the `DOCKER_HOST` Environment Variable:**

    ```bash
    export DOCKER_HOST=tcp://<VM_IP_ADDRESS>:2375
    # Example: export DOCKER_HOST=tcp://192.168.64.73:2375
    ```

2. **Test the Connection:**

    ```bash
    docker info
    docker version
    docker run hello-world
    ```

3. **(Optional) Make it Persistent:**
    Add the export command to your shell profile (e.g., `~/.zshrc`):

    ```bash
    echo 'export DOCKER_HOST=tcp://<VM_IP_ADDRESS>:2375' >> ~/.zshrc
    source ~/.zshrc
    ```
