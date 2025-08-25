# OVN (Open Virtual Network) RPM Builder

Automated RPM building system for OVN (Open Virtual Network) packages targeting Enterprise Linux 9 and 10.

## Features

- **Multi-Distribution Support**: Rocky Linux, AlmaLinux, RHEL 9/10
- **Automated Builds**: Docker-based containerized builds
- **GitHub Integration**: Automated workflows with release monitoring
- **Version Flexibility**: Build any OVN version on demand
- **CI/CD Ready**: Complete GitHub Actions workflows

## Quick Start

### Local Building

```bash
# Build latest OVN version for EL9
make build

# Build specific version for EL10  
make build-el10 OVN_VERSION=24.03.0

# Build for AlmaLinux
make build DISTRO=almalinux

# Clean up
make clean
```

### Manual Docker Build

```bash
# Build OVN 24.09.0 for Rocky Linux 9
docker build --build-arg OVN_VERSION=24.09.0 --build-arg VERSION=9 -t ovn-builder .
docker run --rm -v $(pwd)/output:/output ovn-builder
```

## GitHub Actions

### Automated Release Monitoring

The repository automatically:
- **Monitors** OVN releases every 6 hours
- **Builds** RPMs for new versions (EL9 + EL10)  
- **Creates** GitHub releases with RPM artifacts
- **Prevents** duplicate builds

### Manual Builds

Trigger builds manually via:
- **GitHub UI**: Actions → "Build OVN RPMs" → Run workflow
- **Repository Dispatch**: External automation support
- **Tags**: Push `v24.09.0` tags to trigger builds

## Output

Built RPMs include:
- `ovn-*` - Core OVN packages
- `ovn-central-*` - Central control plane
- `ovn-host-*` - Host/compute node packages
- `ovn-vtep-*` - VTEP emulator
- Source RPMs (SRPMS)

## Requirements

- **Docker** - For containerized builds
- **Make** - For local build automation  
- **GitHub Actions** - For CI/CD (automatic)

## Architecture

```
├── Dockerfile              # Multi-stage RPM build container
├── Makefile                # Local build automation
├── .github/workflows/
│   ├── build.yml           # RPM build workflow
│   └── monitor-ovn-releases.yml  # Release monitoring
└── output/                 # Built RPMs (created during build)
```

## Configuration

### Environment Variables

- `OVN_VERSION` - Target OVN version (default: 24.09.0)
- `DISTRO` - Base distribution (rockylinux, almalinux)  
- `VERSION` - Distribution version (9, 10)

### Supported Versions

- **OVN**: 24.x series and newer
- **Enterprise Linux**: 9, 10 (Rocky, Alma, RHEL)

## Automation

The system provides complete hands-off automation:

1. **Monitor** - Detects new OVN releases via GitHub API
2. **Build** - Automatically builds RPMs for EL9/10
3. **Release** - Creates GitHub releases with RPM artifacts
4. **Distribute** - RPMs available for download immediately

No manual intervention required for new OVN releases!
