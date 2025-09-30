# Simple Cosmos SDK Application Example

This example demonstrates how to create a minimal blockchain application using the Cosmos SDK Go backend.

## Overview

This simple application includes:
- Basic authentication (auth module)
- Token transfers (bank module)  
- Staking and validators (staking module)
- Basic governance (gov module)

## Prerequisites

- Go 1.23.5 or later
- Understanding of the Cosmos SDK architecture
- Familiarity with Go programming

## Application Structure

```
simple-app/
├── app/
│   ├── app.go           # Main application definition
│   ├── app_config.go    # Module configuration
│   └── genesis.go       # Genesis state
├── cmd/
│   └── simpled/
│       └── main.go      # CLI entry point
├── go.mod               # Go module definition
└── README.md            # This file
```

## Getting Started

### Step 1: Define Your Application

Create `app/app.go`:

```go
package app

import (
    "cosmossdk.io/depinject"
    "cosmossdk.io/log"
    "github.com/cosmos/cosmos-sdk/baseapp"
    "github.com/cosmos/cosmos-sdk/runtime"
    "github.com/cosmos/cosmos-sdk/types/module"
    "github.com/cosmos/cosmos-sdk/x/auth"
    authkeeper "github.com/cosmos/cosmos-sdk/x/auth/keeper"
    bankkeeper "cosmossdk.io/x/bank/keeper"
    stakingkeeper "cosmossdk.io/x/staking/keeper"
)

// SimpleApp extends an ABCI application
type SimpleApp struct {
    *runtime.App
    
    // Keepers
    AuthKeeper    authkeeper.AccountKeeper
    BankKeeper    bankkeeper.Keeper
    StakingKeeper *stakingkeeper.Keeper
}

// NewSimpleApp returns a reference to an initialized SimpleApp
func NewSimpleApp(
    logger log.Logger,
    db corestore.KVStoreWithBatch,
) (*SimpleApp, error) {
    var app SimpleApp

    // Load app configuration
    if err := depinject.Inject(
        AppConfig(),
        &app.AuthKeeper,
        &app.BankKeeper,
        &app.StakingKeeper,
    ); err != nil {
        return nil, err
    }

    return &app, nil
}
```

### Step 2: Configure Modules

Create `app/app_config.go`:

```go
package app

import (
    "cosmossdk.io/depinject"
    "cosmossdk.io/depinject/appconfig"
    
    authmodulev1 "cosmossdk.io/api/cosmos/auth/module/v1"
    bankmodulev1 "cosmossdk.io/api/cosmos/bank/module/v1"
    stakingmodulev1 "cosmossdk.io/api/cosmos/staking/module/v1"
)

func AppConfig() depinject.Config {
    return appconfig.Compose(
        &appv1alpha1.Config{
            Modules: []*appv1alpha1.ModuleConfig{
                {
                    Name: "auth",
                    Config: appconfig.WrapAny(&authmodulev1.Module{
                        Bech32Prefix: "simple",
                    }),
                },
                {
                    Name: "bank",
                    Config: appconfig.WrapAny(&bankmodulev1.Module{}),
                },
                {
                    Name: "staking",
                    Config: appconfig.WrapAny(&stakingmodulev1.Module{}),
                },
            },
        },
    )
}
```

### Step 3: Create the CLI

Create `cmd/simpled/main.go`:

```go
package main

import (
    "os"
    
    "github.com/cosmos/cosmos-sdk/server"
    "github.com/spf13/cobra"
    
    "simple-app/app"
)

func main() {
    rootCmd := &cobra.Command{
        Use:   "simpled",
        Short: "Simple blockchain application",
    }
    
    server.AddCommands(
        rootCmd,
        app.DefaultNodeHome,
        func(logger log.Logger, db corestore.KVStoreWithBatch) server.Application {
            simpleApp, err := app.NewSimpleApp(logger, db)
            if err != nil {
                panic(err)
            }
            return simpleApp
        },
    )
    
    if err := rootCmd.Execute(); err != nil {
        os.Exit(1)
    }
}
```

### Step 4: Initialize Go Module

Create `go.mod`:

```go
module simple-app

go 1.23.5

require (
    cosmossdk.io/depinject v1.1.0
    cosmossdk.io/log v1.5.0
    cosmossdk.io/x/bank v0.0.0-latest
    cosmossdk.io/x/staking v0.0.0-latest
    github.com/cosmos/cosmos-sdk v0.50.0-latest
    github.com/spf13/cobra v1.8.1
)
```

## Building and Running

### Build the Application

```bash
go mod tidy
go build -o build/simpled ./cmd/simpled
```

### Initialize a Node

```bash
./build/simpled init mynode --chain-id simple-chain
```

### Add a Genesis Account

```bash
# Create a key
./build/simpled keys add validator

# Add genesis account
./build/simpled genesis add-genesis-account validator 1000000000stake
```

### Create Genesis Transaction

```bash
./build/simpled genesis gentx validator 100000000stake \
    --chain-id simple-chain
```

### Collect Genesis Transactions

```bash
./build/simpled genesis collect-gentxs
```

### Start the Node

```bash
./build/simpled start
```

## Interacting with Your Blockchain

### Query Account

```bash
./build/simpled query auth account $(./build/simpled keys show validator -a)
```

### Query Balances

```bash
./build/simpled query bank balances $(./build/simpled keys show validator -a)
```

### Send Tokens

```bash
# Create another account
./build/simpled keys add user

# Send tokens
./build/simpled tx bank send validator $(./build/simpled keys show user -a) \
    1000stake --chain-id simple-chain -y
```

### Delegate to Validator

```bash
./build/simpled tx staking delegate \
    $(./build/simpled keys show validator --bech=val -a) \
    100stake --from validator --chain-id simple-chain -y
```

### Query Validators

```bash
./build/simpled query staking validators
```

## Adding Custom Functionality

### Create a Custom Module

1. Create module directory: `x/mymodule/`
2. Define types: `x/mymodule/types/`
3. Implement keeper: `x/mymodule/keeper/`
4. Add to app config

Example custom module structure:

```go
// x/mymodule/keeper/keeper.go
package keeper

type Keeper struct {
    storeService store.KVStoreService
}

func (k Keeper) SetValue(ctx context.Context, key, value string) error {
    // Custom logic here
    return nil
}

func (k Keeper) GetValue(ctx context.Context, key string) (string, error) {
    // Custom logic here
    return "", nil
}
```

### Register Custom Module

In `app_config.go`:

```go
{
    Name: "mymodule",
    Config: appconfig.WrapAny(&mymodulev1.Module{}),
}
```

## Testing Your Application

### Unit Tests

```go
func TestKeeper(t *testing.T) {
    ctx, keeper := setupTest(t)
    
    // Test your keeper logic
    err := keeper.SetValue(ctx, "key", "value")
    require.NoError(t, err)
    
    value, err := keeper.GetValue(ctx, "key")
    require.NoError(t, err)
    require.Equal(t, "value", value)
}
```

### Integration Tests

```go
func TestIntegration(t *testing.T) {
    app, err := app.NewSimpleApp(log.NewNopLogger(), db)
    require.NoError(t, err)
    
    // Test full application flow
}
```

## Next Steps

1. **Add More Modules**: Include governance, distribution, etc.
2. **Custom Messages**: Define your own transaction types
3. **Events and Hooks**: Add custom event emissions
4. **REST API**: Enable gRPC-Gateway for REST endpoints
5. **WebSocket**: Add real-time event subscriptions

## Common Patterns

### State Management

```go
// Using collections for type-safe state
import "cosmossdk.io/collections"

type Keeper struct {
    users collections.Map[string, User]
}

func NewKeeper(storeService store.KVStoreService) Keeper {
    sb := collections.NewSchemaBuilder(storeService)
    return Keeper{
        users: collections.NewMap(
            sb,
            collections.NewPrefix(1),
            "users",
            collections.StringKey,
            codec.CollValue[User](cdc),
        ),
    }
}
```

### Message Handling

```go
func (k msgServer) CreateUser(
    ctx context.Context,
    msg *types.MsgCreateUser,
) (*types.MsgCreateUserResponse, error) {
    // Validate
    if err := msg.ValidateBasic(); err != nil {
        return nil, err
    }
    
    // Execute
    user := types.User{
        Address: msg.Creator,
        Name:    msg.Name,
    }
    
    if err := k.users.Set(ctx, msg.Creator, user); err != nil {
        return nil, err
    }
    
    // Emit event
    sdk.UnwrapSDKContext(ctx).EventManager().EmitEvent(
        sdk.NewEvent(
            "user_created",
            sdk.NewAttribute("creator", msg.Creator),
            sdk.NewAttribute("name", msg.Name),
        ),
    )
    
    return &types.MsgCreateUserResponse{}, nil
}
```

### Query Handling

```go
func (k queryServer) GetUser(
    ctx context.Context,
    req *types.QueryGetUserRequest,
) (*types.QueryGetUserResponse, error) {
    user, err := k.users.Get(ctx, req.Address)
    if err != nil {
        return nil, err
    }
    
    return &types.QueryGetUserResponse{
        User: &user,
    }, nil
}
```

## Resources

- **Cosmos SDK Docs**: https://docs.cosmos.network
- **SimApp Reference**: See `../../simapp/` directory
- **Tutorials**: https://tutorials.cosmos.network
- **Module Development**: `../../docs/build/building-modules/`

## Support

For help with this example:
- Check the main README.md
- Review IMPLEMENTATION.md for detailed architecture
- Join the Cosmos Discord: https://discord.gg/interchain
