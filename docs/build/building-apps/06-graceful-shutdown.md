# Graceful Shutdown in Cosmos SDK

This document explains how to properly shutdown a Cosmos SDK application to ensure all resources are cleaned up correctly.

## Overview

The Cosmos SDK provides graceful shutdown mechanisms through the `Close()` method available on both `BaseApp` and the runtime `App`. This method ensures that all resources are properly cleaned up when the application terminates.

## What Gets Cleaned Up

When `Close()` is called, the following resources are properly cleaned up:

1. **Database connections** - The main application database is closed
2. **Snapshot manager** - Any snapshot store and metadata database connections are closed
3. **Optimistic execution** - Any running optimistic execution processes are aborted and cleaned up
4. **Unordered transaction manager** (runtime/App only) - Cleans up transaction processing resources

## Basic Usage

### For Applications Using BaseApp Directly

```go
import (
    "cosmossdk.io/log"
    "cosmossdk.io/store/dbm"
    "github.com/cosmos/cosmos-sdk/baseapp"
)

func main() {
    // Create your application
    logger := log.NewNopLogger()
    db := dbm.NewMemDB()
    defer db.Close()
    
    app := baseapp.NewBaseApp("myapp", logger, db, nil)
    
    // ... configure your application ...
    
    // Always call Close() before exiting
    defer func() {
        if err := app.Close(); err != nil {
            logger.Error("Error closing application", "error", err)
        }
    }()
    
    // ... run your application ...
}
```

### For Applications Using runtime.App

```go
import (
    "cosmossdk.io/log"
    "cosmossdk.io/store/dbm"
    "github.com/cosmos/cosmos-sdk/runtime"
)

func main() {
    // Create your runtime application
    logger := log.NewNopLogger()
    db := dbm.NewMemDB()
    defer db.Close()
    
    app := &runtime.App{
        BaseApp: baseapp.NewBaseApp("myapp", logger, db, nil),
        // ... other runtime app configuration ...
    }
    
    // Always call Close() before exiting
    defer func() {
        if err := app.Close(); err != nil {
            logger.Error("Error closing application", "error", err)
        }
    }()
    
    // ... run your application ...
}
```

## Server Integration

The Cosmos SDK server automatically handles graceful shutdown when using the standard server commands. The server listens for termination signals and calls `Close()` appropriately.

You can configure graceful shutdown behavior using the `--shutdown-grace` flag:

```bash
# Allow 10 seconds for graceful shutdown
myapp start --shutdown-grace=10s
```

## Error Handling

The `Close()` method returns an error that combines all errors encountered during cleanup. It's important to handle this error appropriately:

```go
if err := app.Close(); err != nil {
    // Log the error
    logger.Error("Failed to close application cleanly", "error", err)
    
    // You may want to exit with a non-zero status code
    os.Exit(1)
}
```

## Best Practices

1. **Always call Close()** - Use `defer` statements to ensure `Close()` is called even if your application panics
2. **Handle errors** - Log any errors returned by `Close()` for debugging purposes
3. **Close order** - Close the application before closing the underlying database
4. **Multiple calls** - It's safe to call `Close()` multiple times; subsequent calls will be no-ops

## Example: Signal Handling

Here's a complete example that properly handles shutdown signals:

```go
package main

import (
    "context"
    "os"
    "os/signal"
    "syscall"
    "time"

    "cosmossdk.io/log"
    "cosmossdk.io/store/dbm"
    "github.com/cosmos/cosmos-sdk/baseapp"
)

func main() {
    logger := log.NewNopLogger()
    db := dbm.NewMemDB()
    defer db.Close()
    
    app := baseapp.NewBaseApp("myapp", logger, db, nil)
    
    // Set up signal handling for graceful shutdown
    ctx, cancel := context.WithCancel(context.Background())
    defer cancel()
    
    // Channel to listen for interrupt signal
    c := make(chan os.Signal, 1)
    signal.Notify(c, os.Interrupt, syscall.SIGTERM)
    
    go func() {
        <-c
        logger.Info("Received shutdown signal, starting graceful shutdown...")
        cancel()
    }()
    
    // Ensure cleanup happens
    defer func() {
        logger.Info("Closing application...")
        if err := app.Close(); err != nil {
            logger.Error("Error during shutdown", "error", err)
            os.Exit(1)
        }
        logger.Info("Application closed successfully")
    }()
    
    // Run your application logic here
    // ... your application logic ...
    
    // Wait for cancellation
    <-ctx.Done()
    logger.Info("Shutting down...")
}
```

This ensures that your Cosmos SDK application shuts down gracefully, properly cleaning up all resources and avoiding data corruption or resource leaks.