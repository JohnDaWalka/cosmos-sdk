# Cosmos SDK Go Backend - Quick Start Guide

This guide will help you get started with the Cosmos SDK Go backend implementation in this repository.

## Prerequisites

- **Go 1.23.5 or later** - [Download Go](https://go.dev/dl)
- **Make** - Build automation tool
- **Git** - Version control

## What is Cosmos SDK?

The Cosmos SDK is a framework for building blockchain applications in Go. It provides:

- **Modular architecture** - Build custom blockchain applications with reusable modules
- **CometBFT consensus** - Byzantine Fault Tolerant consensus engine
- **Inter-Blockchain Communication (IBC)** - Connect with other blockchains
- **Built-in modules** - Auth, Bank, Staking, Governance, and more

## Quick Start

### 1. Clone the Repository

```bash
git clone https://github.com/mauromarknazarenofanelli/cosmos-sdk.git
cd cosmos-sdk
```

### 2. Install Dependencies

The project uses Go modules for dependency management. Update dependencies:

```bash
go mod tidy
cd simapp && go mod tidy && cd ..
```

### 3. Build the Application

Build the example `simd` application:

```bash
make build
```

The binary will be created in the `build/` directory:

```bash
./build/simd version
```

### 4. Initialize a Local Node

Initialize a new blockchain node:

```bash
./build/simd init mynode --chain-id mychain
```

### 5. Run the Node

Start your blockchain node:

```bash
./build/simd start
```

## Project Structure

```
cosmos-sdk/
├── baseapp/          # Base ABCI application
├── client/           # Client libraries
├── codec/            # Encoding/decoding
├── core/             # Core interfaces and types
├── crypto/           # Cryptographic functions
├── server/           # Server implementation
├── simapp/           # Example application
│   ├── app.go        # Main application setup
│   ├── simd/         # CLI binary
│   └── ...
├── store/            # Storage layer
├── types/            # Common types
└── x/                # Standard modules
    ├── auth/         # Authentication
    ├── bank/         # Token transfers
    ├── staking/      # Proof of Stake
    ├── gov/          # Governance
    └── ...
```

## Building Your Own Blockchain Application

### 1. Using SimApp as a Template

The `simapp` directory contains a complete example application. You can use it as a template:

1. Copy the `simapp` directory to your project
2. Customize the modules and configuration
3. Build and deploy

### 2. Key Files to Customize

- **app.go** - Main application setup and module configuration
- **app_config.go** - Module wiring and dependency injection
- **genesis.go** - Genesis state configuration
- **simd/main.go** - CLI entry point

### 3. Adding Custom Modules

You can add custom modules to your application:

```go
// In app.go or app_config.go
import (
    "your-repo/x/custom-module"
)

// Configure your module in the app config
```

## Available Modules

This implementation includes these standard modules:

- **auth** - Account authentication
- **authz** - Authorization for accounts
- **bank** - Token transfer functionality
- **circuit** - Circuit breaker for pausing messages
- **consensus** - Consensus parameter management
- **distribution** - Fee distribution and rewards
- **epochs** - Epoch-based triggers
- **evidence** - Evidence handling for misbehavior
- **feegrant** - Fee allowances
- **gov** - Governance proposals and voting
- **group** - Group accounts and decision-making
- **mint** - Token minting
- **nft** - Non-fungible tokens
- **protocolpool** - Protocol fee pool
- **slashing** - Validator slashing
- **staking** - Proof of Stake
- **upgrade** - Chain upgrades
- **validate** - Transaction validation

## Development Commands

### Build Commands

```bash
# Build the main application
make build

# Build for specific platform
make build-linux-amd64
make build-linux-arm64

# Build additional tools
make cosmovisor  # Upgrade manager
make confix      # Configuration tool
make hubl        # Hub client
```

### Testing Commands

```bash
# Run all tests
make test

# Run tests with coverage
make test-coverage

# Run integration tests
make test-integration

# Run simulations
make test-sim-nondeterminism
make test-sim-import-export
```

### Code Quality

```bash
# Format code
make format

# Run linter
make lint

# Run vulnerability check
make vulncheck
```

## Working with the CLI

### Initialize a Chain

```bash
./build/simd init <node-name> --chain-id <chain-id>
```

### Add Keys

```bash
./build/simd keys add <key-name>
./build/simd keys list
```

### Query Commands

```bash
# Query account
./build/simd query auth account <address>

# Query bank balance
./build/simd query bank balances <address>

# Query staking validators
./build/simd query staking validators
```

### Transaction Commands

```bash
# Send tokens
./build/simd tx bank send <from> <to> <amount> --chain-id <chain-id>

# Delegate to validator
./build/simd tx staking delegate <validator-addr> <amount> --from <key-name>

# Submit governance proposal
./build/simd tx gov submit-proposal <proposal.json> --from <key-name>
```

## Configuration

### App Configuration

The app configuration is defined in `simapp/app_config.go` using dependency injection:

```go
func AppConfig() depinject.Config {
    return depinject.Configs(
        appconfig.Compose(appConfig),
        depinject.Supply(
            // Supply custom dependencies
        ),
    )
}
```

### Server Configuration

Server settings are in `~/.simapp/config/`:

- **app.toml** - Application configuration
- **config.toml** - CometBFT configuration
- **genesis.json** - Genesis state

## Integration with IBC

For Inter-Blockchain Communication:

1. Add IBC module: [cosmos/ibc-go](https://github.com/cosmos/ibc-go)
2. Configure IBC in your app
3. Enable relayers for cross-chain transfers

## Integration with CosmWasm

For smart contract support:

1. Add CosmWasm module: [CosmWasm](https://github.com/CosmWasm/cosmwasm)
2. Enable WASM in your app configuration
3. Deploy and interact with smart contracts

## Upgrade Management with Cosmovisor

Cosmovisor handles automatic binary upgrades:

```bash
# Install cosmovisor
make cosmovisor

# Setup cosmovisor
export DAEMON_NAME=simd
export DAEMON_HOME=$HOME/.simapp
cosmovisor init ./build/simd

# Run with cosmovisor
cosmovisor run start
```

## Resources

- **Official Documentation**: [docs.cosmos.network](https://docs.cosmos.network)
- **Cosmos SDK Repository**: [github.com/cosmos/cosmos-sdk](https://github.com/cosmos/cosmos-sdk)
- **Tutorials**: [tutorials.cosmos.network](https://tutorials.cosmos.network)
- **Discord Community**: [discord.gg/interchain](https://discord.gg/interchain)
- **IBC Protocol**: [github.com/cosmos/ibc-go](https://github.com/cosmos/ibc-go)
- **CosmWasm**: [book.cosmwasm.com](https://book.cosmwasm.com)

## Troubleshooting

### Build Issues

If you encounter build errors:

```bash
# Clean build artifacts
make clean

# Update dependencies
go mod tidy
cd simapp && go mod tidy && cd ..

# Rebuild
make build
```

### Version Compatibility

Ensure you're using Go 1.23.5 or later:

```bash
go version
```

### Module Dependencies

Check the version matrix in [README.md](./README.md) for compatible module versions.

## Next Steps

1. **Explore SimApp** - Study the example application in `simapp/`
2. **Read Architecture Docs** - Check `docs/architecture/` for design decisions
3. **Build Custom Modules** - Follow guides in `docs/build/building-modules/`
4. **Join the Community** - Connect on [Discord](https://discord.gg/interchain)

## Contributing

See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines on contributing to the Cosmos SDK.

## License

This project is licensed under the Apache 2.0 License - see [LICENSE](./LICENSE) for details.
