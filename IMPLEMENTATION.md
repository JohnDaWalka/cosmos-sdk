# Cosmos SDK Go Backend Implementation Guide

This document provides a comprehensive guide to implementing and understanding the Cosmos SDK Go backend architecture in this repository.

## Overview

The Cosmos SDK is implemented in Go and provides a modular framework for building blockchain applications. This implementation follows the official Cosmos SDK architecture with all core modules and functionality.

## Architecture Components

### 1. Core Framework

#### BaseApp (`baseapp/`)

The foundation of any Cosmos SDK application. BaseApp implements the ABCI (Application Blockchain Interface) that connects to CometBFT consensus engine.

**Key responsibilities:**
- Process transactions
- Execute state transitions
- Handle queries
- Manage module routing

**Example usage:**
```go
import "github.com/cosmos/cosmos-sdk/baseapp"

app := baseapp.NewBaseApp(
    appName,
    logger,
    db,
    txDecoder,
    baseAppOptions...,
)
```

#### Runtime (`runtime/`)

Provides runtime services and app wiring using dependency injection.

**Features:**
- Module registration
- Service provisioning
- App initialization

### 2. State Management

#### Store (`store/`)

Multi-store implementation for blockchain state management.

**Store types:**
- **CommitKVStore** - Persistent key-value store
- **TransientStore** - Temporary store cleared each block
- **MemoryStore** - In-memory store

**Example:**
```go
import "cosmossdk.io/store"

// Access a module's store
storeKey := storetypes.NewKVStoreKey("bank")
kvStore := ctx.KVStore(storeKey)
```

#### Collections (`collections/`)

Type-safe collections for state management.

**Collection types:**
- Maps
- Sequences
- Indexed maps

### 3. Transaction Processing

#### Codec (`codec/`)

Handles encoding and decoding of transactions and state.

**Supported formats:**
- Protocol Buffers (primary)
- Amino (legacy)
- JSON (for REST API)

#### AnteHandler (`x/auth/ante/`)

Pre-processes transactions before execution.

**Checks:**
- Signature verification
- Fee payment
- Nonce validation
- Gas limits

### 4. Module System

#### Module Manager

Coordinates all application modules.

**Lifecycle hooks:**
- InitGenesis
- BeginBlock
- EndBlock
- ExportGenesis

#### Standard Modules (`x/`)

Pre-built modules for common blockchain functionality:

##### Auth Module (`x/auth/`)
Manages accounts and authentication.

```go
import authkeeper "github.com/cosmos/cosmos-sdk/x/auth/keeper"

authKeeper := authkeeper.NewAccountKeeper(
    cdc,
    storeKey,
    accountTypes,
)
```

##### Bank Module (`x/bank/`)
Handles token transfers and balances.

```go
import bankkeeper "cosmossdk.io/x/bank/keeper"

bankKeeper := bankkeeper.NewBaseKeeper(
    cdc,
    storeKey,
    authKeeper,
    blockedAddrs,
)
```

##### Staking Module (`x/staking/`)
Implements Proof of Stake consensus.

**Features:**
- Validator registration
- Delegation
- Rewards distribution
- Slashing

##### Governance Module (`x/gov/`)
On-chain governance with proposals and voting.

**Proposal types:**
- Text proposals
- Parameter changes
- Software upgrades
- Custom proposals

### 5. Client Libraries

#### CLI (`client/`)

Command-line interface framework.

**Components:**
- Command builders
- Flag parsing
- Transaction creation
- Query execution

#### gRPC (`server/grpc/`)

gRPC server for querying and broadcasting transactions.

**Services:**
- Query services
- Transaction services
- Reflection API

#### REST API (`server/api/`)

RESTful HTTP API using gRPC-Gateway.

### 6. Cryptography (`crypto/`)

Cryptographic primitives and key management.

**Supported algorithms:**
- secp256k1 (Bitcoin-style)
- ed25519
- sr25519

**Key types:**
- Private keys
- Public keys
- Addresses

### 7. Networking

#### CometBFT Integration

Connects to CometBFT for consensus and networking.

**ABCI methods:**
- InitChain
- BeginBlock
- DeliverTx
- EndBlock
- Commit

## Building a Custom Application

### Step 1: Define Your App Structure

Create the main app file:

```go
package app

import (
    "cosmossdk.io/depinject"
    "github.com/cosmos/cosmos-sdk/baseapp"
    "github.com/cosmos/cosmos-sdk/runtime"
)

type MyApp struct {
    *runtime.App
    
    // Module keepers
    AuthKeeper auth.AccountKeeper
    BankKeeper bank.Keeper
    // ... other keepers
}
```

### Step 2: Configure Modules

Use dependency injection for module configuration:

```go
func AppConfig() depinject.Config {
    return appconfig.Compose(
        &appv1alpha1.Config{
            Modules: []*appv1alpha1.ModuleConfig{
                {
                    Name: "auth",
                    Config: appconfig.WrapAny(&authmodulev1.Module{}),
                },
                {
                    Name: "bank",
                    Config: appconfig.WrapAny(&bankmodulev1.Module{}),
                },
                // ... more modules
            },
        },
    )
}
```

### Step 3: Initialize the App

```go
func NewMyApp(
    logger log.Logger,
    db dbm.DB,
    traceStore io.Writer,
    appOpts servertypes.AppOptions,
) *MyApp {
    var app MyApp
    
    if err := depinject.Inject(
        AppConfig(),
        &app.AuthKeeper,
        &app.BankKeeper,
        // ... inject other keepers
    ); err != nil {
        panic(err)
    }
    
    return &app
}
```

### Step 4: Create the CLI

```go
package main

import (
    "github.com/cosmos/cosmos-sdk/server"
    "github.com/spf13/cobra"
)

func main() {
    rootCmd := &cobra.Command{
        Use:   "myappd",
        Short: "My blockchain application",
    }
    
    server.AddCommands(rootCmd, app.DefaultNodeHome, app.NewMyApp)
    
    if err := rootCmd.Execute(); err != nil {
        os.Exit(1)
    }
}
```

## Creating Custom Modules

### Module Structure

```
x/mymodule/
├── keeper/           # Business logic
│   ├── keeper.go     # Keeper definition
│   ├── msg_server.go # Message handlers
│   └── query_server.go # Query handlers
├── types/            # Type definitions
│   ├── keys.go       # Store keys
│   ├── msgs.go       # Message types
│   └── genesis.go    # Genesis state
├── module.go         # Module interface implementation
└── depinject.go      # Dependency injection
```

### Keeper Implementation

```go
package keeper

import (
    "cosmossdk.io/core/store"
    "cosmossdk.io/collections"
)

type Keeper struct {
    storeService store.KVStoreService
    
    // State collections
    balances collections.Map[sdk.AccAddress, sdk.Coin]
}

func NewKeeper(storeService store.KVStoreService) Keeper {
    sb := collections.NewSchemaBuilder(storeService)
    
    return Keeper{
        storeService: storeService,
        balances: collections.NewMap(
            sb, 
            collections.NewPrefix(1),
            "balances",
            collections.AccAddressKey,
            codec.CollValue[sdk.Coin](cdc),
        ),
    }
}
```

### Message Handler

```go
func (k msgServer) Send(
    ctx context.Context,
    msg *types.MsgSend,
) (*types.MsgSendResponse, error) {
    // Validate message
    if err := msg.ValidateBasic(); err != nil {
        return nil, err
    }
    
    // Execute business logic
    if err := k.SendCoins(ctx, msg.FromAddress, msg.ToAddress, msg.Amount); err != nil {
        return nil, err
    }
    
    // Emit event
    sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
        sdk.NewEvent(
            types.EventTypeSend,
            sdk.NewAttribute(types.AttributeKeySender, msg.FromAddress),
            sdk.NewAttribute(types.AttributeKeyReceiver, msg.ToAddress),
        ),
    )
    
    return &types.MsgSendResponse{}, nil
}
```

### Module Interface

```go
package mymodule

import (
    "cosmossdk.io/core/appmodule"
    "github.com/cosmos/cosmos-sdk/types/module"
)

var (
    _ module.AppModule = AppModule{}
    _ appmodule.AppModule = AppModule{}
)

type AppModule struct {
    keeper keeper.Keeper
}

func (am AppModule) RegisterServices(cfg module.Configurator) {
    types.RegisterMsgServer(cfg.MsgServer(), keeper.NewMsgServer(am.keeper))
    types.RegisterQueryServer(cfg.QueryServer(), keeper.NewQueryServer(am.keeper))
}
```

## State Machine Design

### Transaction Lifecycle

1. **Submission**: Client submits transaction
2. **Mempool**: Transaction enters mempool
3. **Consensus**: Included in block proposal
4. **AnteHandler**: Pre-execution checks
5. **Message Routing**: Route to appropriate module
6. **Execution**: Module processes message
7. **State Commit**: State changes committed
8. **Events**: Events emitted

### State Transitions

```go
// BeginBlock: Execute at start of block
func (k Keeper) BeginBlock(ctx sdk.Context) {
    // Perform block-level operations
}

// Message handling: Process individual messages
func (k Keeper) HandleMsg(ctx sdk.Context, msg sdk.Msg) error {
    // Update state based on message
}

// EndBlock: Execute at end of block
func (k Keeper) EndBlock(ctx sdk.Context) []abci.ValidatorUpdate {
    // Finalize block operations
    // Return validator updates if needed
}
```

## Testing

### Unit Tests

```go
func TestKeeper_Send(t *testing.T) {
    ctx, keeper := setupTest(t)
    
    sender := sdk.AccAddress([]byte("sender"))
    receiver := sdk.AccAddress([]byte("receiver"))
    amount := sdk.NewCoins(sdk.NewCoin("stake", sdk.NewInt(100)))
    
    // Fund sender
    require.NoError(t, keeper.MintCoins(ctx, sender, amount))
    
    // Test send
    err := keeper.SendCoins(ctx, sender, receiver, amount)
    require.NoError(t, err)
    
    // Verify balances
    senderBal := keeper.GetBalance(ctx, sender)
    require.True(t, senderBal.IsZero())
    
    receiverBal := keeper.GetBalance(ctx, receiver)
    require.Equal(t, amount, receiverBal)
}
```

### Integration Tests

```go
func TestIntegration(t *testing.T) {
    app := simapp.Setup(t, false)
    ctx := app.BaseApp.NewContext(false)
    
    // Test full transaction flow
    msg := banktypes.NewMsgSend(sender, receiver, coins)
    tx := createTx(t, msg)
    
    res := app.DeliverTx(abci.RequestDeliverTx{
        Tx: tx,
    })
    require.Equal(t, uint32(0), res.Code)
}
```

## Performance Optimization

### Caching

```go
// Use cached context for state queries
cachedCtx, _ := ctx.CacheContext()

// Perform operations on cached context
result := keeper.Query(cachedCtx)

// Write cache if needed
// (cache is discarded if not explicitly written)
```

### Gas Metering

```go
// Charge gas for operations
ctx.GasMeter().ConsumeGas(gasCost, "operation description")

// Check gas limits
if ctx.GasMeter().IsOutOfGas() {
    return errors.New("out of gas")
}
```

### Indexing

```go
// Use collections with secondary indexes
type Keeper struct {
    balances collections.Map[[]byte, Coin]
    
    // Index balances by owner
    balancesByOwner collections.MultiIndex[AccAddress, []byte, Coin]
}
```

## Security Best Practices

1. **Input Validation**: Always validate message inputs
2. **Access Control**: Check permissions before state changes
3. **Reentrancy**: Use mutex patterns for critical sections
4. **Gas Limits**: Enforce computational limits
5. **Integer Overflow**: Use safe math operations

## Deployment

### Building for Production

```bash
# Build with optimizations
make build LEDGER_ENABLED=false

# Build for specific platform
make build-linux-amd64

# Create release binary
make release
```

### Running a Node

```bash
# Initialize node
./simd init mynode --chain-id mainnet

# Configure genesis
./simd genesis add-genesis-account <address> 1000000stake

# Start node
./simd start --home ~/.simapp
```

### Monitoring

- **Prometheus metrics**: Enabled via app.toml
- **Event indexing**: CometBFT event indexer
- **Logging**: Structured logging with zerolog

## Migration Guide

When upgrading the SDK version:

1. Review UPGRADING.md for breaking changes
2. Update go.mod dependencies
3. Run tests to identify issues
4. Update deprecated API usage
5. Test upgrade on testnet

## Additional Resources

- **Module Development**: `docs/build/building-modules/`
- **Architecture Decisions**: `docs/architecture/`
- **API Reference**: [pkg.go.dev/github.com/cosmos/cosmos-sdk](https://pkg.go.dev/github.com/cosmos/cosmos-sdk)
- **Example Apps**: `simapp/`, test applications
- **Community**: [Discord](https://discord.gg/interchain)

## Support

For questions and support:

- **GitHub Issues**: Report bugs and feature requests
- **Discord**: Join the Cosmos developer community
- **Forum**: [forum.cosmos.network](https://forum.cosmos.network)
- **Documentation**: [docs.cosmos.network](https://docs.cosmos.network)
