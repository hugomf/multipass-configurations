# Automated Kafka VM Setup with Multipass and Cloud-Init

This project provides a fully automated setup for a single-node Apache Kafka 4.0.0 cluster running in KRaft mode on an Ubuntu 24.04 Multipass VM.

## Features

- **Fully Automated**: Single command to create a complete Kafka environment.
- **Latest Kafka Version**: Installs Kafka 4.0.0, the latest available version.
- **Modern KRaft Mode**: No ZooKeeper dependency, using the latest architecture.
- **Systemd Service**: Manages Kafka as a service for easy start/stop/restart.
- **Failure Protection**: Built-in timeout and intelligent failure detection.
- **Smart Monitoring**: Progress updates and automatic recovery from partial failures.
- **Repeatable & Clean**: Easily create and destroy Kafka environments for development and testing.

## Prerequisites

- [Multipass](https://multipass.run/install) must be installed on your system (macOS, Windows, or Linux).

## Quick Start

1.  **Clone or download** this project repository.
2.  **Navigate** to the project directory:
    ```bash
    cd Projects/multipass-configuration/kafka-setup
    ```
3.  **Run the launch script**:
    ```bash
    ./launch-kafka-vm.sh
    ```

The script will:
1.  Create a new Multipass VM named `kafka-vm-auto`.
2.  Use `kafka-cloud-init.yaml` to install Java, Kafka, and all dependencies.
3.  Configure Kafka to run in KRaft mode.
4.  Set up a `systemd` service to manage Kafka automatically.
5.  Monitor the setup process and notify you when it's complete.
6.  Display the VM's IP address and connection details.

## What's Included

- `launch-kafka-vm.sh`: The main script to create and configure the VM. It handles VM creation, deletion (with confirmation), and provides status updates.
- `kafka-cloud-init.yaml`: The `cloud-init` configuration file that contains all the setup steps, from package installation to service creation.

## After Setup

Once the script completes, you will have a fully functional Kafka broker running. You can connect to it using the IP address provided in the script's output.

### Connecting to the VM

```bash
multipass shell kafka-vm-auto
```

### Managing the Kafka Service

- **Check status**:
  ```bash
  multipass exec kafka-vm-auto -- sudo systemctl status kafka
  ```
- **Stop Kafka**:
  ```bash
  multipass exec kafka-vm-auto -- sudo systemctl stop kafka
  ```
- **Start Kafka**:
  ```bash
  multipass exec kafka-vm-auto -- sudo systemctl start kafka
  ```
- **Restart Kafka**:
  ```bash
  multipass exec kafka-vm-auto -- sudo systemctl restart kafka
  ```

### Testing Kafka

- **Create a topic**:
  ```bash
  multipass exec kafka-vm-auto -- /opt/kafka/bin/kafka-topics.sh --create --topic my-test-topic --bootstrap-server localhost:9092
  ```
- **Send messages**:
  ```bash
  multipass exec kafka-vm-auto -- /opt/kafka/bin/kafka-console-producer.sh --topic my-test-topic --bootstrap-server localhost:9092
  ```
- **Consume messages**:
  ```bash
  multipass exec kafka-vm-auto -- /opt/kafka/bin/kafka-console-consumer.sh --topic my-test-topic --from-beginning --bootstrap-server localhost:9092
  ```

## Customization

- **VM Name**: Edit the `VM_NAME` variable in `launch-kafka-vm.sh`.
- **VM Resources**: Modify the `--cpus`, `--memory`, and `--disk` flags in `launch-kafka-vm.sh`.
- **Kafka Configuration**: Edit the `runcmd` section in `kafka-cloud-init.yaml` to change Kafka settings.

