# multipass-configurations

A collection of configuration guides for setting up various containerization and virtualization solutions using Multipass on macOS.

## Configuration Guides

| Guide | Description |
|-------|-------------|
| [Incus Configuration](incus-conf.md) | Set up Incus container management with macvlan networking for direct network access |
| [LXD Configuration](lxd-conf.md) | Configure LXD containers with macvlan networking and Amazon Linux support |
| [Remote Docker Configuration](remote-docker-conf.md) | Control Docker daemon running in Multipass VM from macOS host |

## Quick Start

All guides assume you have:
- Multipass installed on macOS
- Basic familiarity with command line operations
- Network bridge configuration (`mp set local.bridged-network=en0`)

## Features

- **Macvlan Networking**: Direct network access for containers bypassing WiFi bridging limitations
- **Multi-architecture Support**: ARM and Intel/AMD configurations
- **Amazon Linux Support**: Special configurations for running Amazon Linux images
- **Remote Access**: Secure and insecure connection options

Choose the configuration guide that matches your containerization needs.
