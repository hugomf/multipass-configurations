# Configuring Remote Docker Access from macOS to Multipass Ubuntu VM

This guide explains how to configure remote Docker access from your **macOS** host machine to control a Docker daemon running inside a Multipass Ubuntu VM. This setup allows you to execute `docker` commands locally from your **macOS** terminal while the actual Docker containers run inside the **Multipass Ubuntu 24.04 VM**, effectively avoiding the need to install Docker Desktop on your **macOS** host machine.

**Key Benefits:**
- Use native `docker` CLI commands from macOS without Docker Desktop
- Containers run in an isolated Ubuntu VM environment
- Leverages Multipass for lightweight VM management
- Maintains separation between host OS and container runtime

**Architecture Overview:**
Your macOS host acts as a Docker client that communicates with the Docker daemon running in the Ubuntu VM over the network, providing a seamless container development experience without the overhead of Docker Desktop.

```mermaid
graph LR
    A[macOS Terminal<br/>Docker CLI] -->|Docker Commands| B[Network<br/>TCP Connection]
    B -->|Remote API| C[Ubuntu VM<br/>Docker Daemon]
    C --> D[Containers]
    
    E[Multipass] -.->|Manages| C
    
    style A fill:#e1f5fe
    style C fill:#c8e6c9
    style D fill:#ffecb3
    style E fill:#fff3e0
 ```

## Prerequisites

### On macOS Host:

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

### Inside VM (via `mp shell docker`):

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

* Go back to your host machine

```bash
exit
```

---

### On macOS Host:

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
