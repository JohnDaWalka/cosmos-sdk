package baseapp_test

import (
	"testing"

	"github.com/stretchr/testify/require"

	coretesting "cosmossdk.io/core/testing" 
	"cosmossdk.io/log"
	"cosmossdk.io/store/snapshots"
	snapshottypes "cosmossdk.io/store/snapshots/types"

	"github.com/cosmos/cosmos-sdk/baseapp"
	"github.com/cosmos/cosmos-sdk/testutil"
)

func TestBaseApp_Close(t *testing.T) {
	// Create a test database
	db := coretesting.NewMemDB()
	defer db.Close()

	// Create logger
	logger := log.NewNopLogger()

	// Create the app
	app := baseapp.NewBaseApp("test", logger, db, nil)

	// Test closing a basic app
	err := app.Close()
	require.NoError(t, err, "Basic Close() should not error")

	// Test closing an already closed app (should be safe to call multiple times)
	err = app.Close()
	require.NoError(t, err, "Close() should be safe to call multiple times")
}

func TestBaseApp_CloseWithSnapshotManager(t *testing.T) {
	// Create a test database
	db := coretesting.NewMemDB()
	defer db.Close()

	// Create a snapshot store
	snapshotDB := coretesting.NewMemDB()
	defer snapshotDB.Close()
	snapshotStore, err := snapshots.NewStore(snapshotDB, testutil.GetTempDir(t))
	require.NoError(t, err)

	// Create logger
	logger := log.NewNopLogger()

	// Create the app with snapshot manager
	app := baseapp.NewBaseApp("test", logger, db, nil, baseapp.SetSnapshot(snapshotStore, snapshottypes.NewSnapshotOptions(1, 10)))

	// Test closing app with snapshot manager
	err = app.Close()
	require.NoError(t, err, "Close() with snapshot manager should not error")
}

func TestBaseApp_CloseWithOptimisticExecution(t *testing.T) {
	// Create a test database
	db := coretesting.NewMemDB()
	defer db.Close()

	// Create logger
	logger := log.NewNopLogger()

	// Create the app with optimistic execution enabled
	app := baseapp.NewBaseApp("test", logger, db, nil, baseapp.SetOptimisticExecution())

	// Test closing app with optimistic execution
	err := app.Close()
	require.NoError(t, err, "Close() with optimistic execution should not error")
}

func TestBaseApp_CloseWithAllComponents(t *testing.T) {
	// Create a test database
	db := coretesting.NewMemDB()
	defer db.Close()

	// Create a snapshot store
	snapshotDB := coretesting.NewMemDB()
	defer snapshotDB.Close()
	snapshotStore, err := snapshots.NewStore(snapshotDB, testutil.GetTempDir(t))
	require.NoError(t, err)

	// Create logger
	logger := log.NewNopLogger()

	// Create the app with all components
	app := baseapp.NewBaseApp("test", logger, db, nil,
		baseapp.SetSnapshot(snapshotStore, snapshottypes.NewSnapshotOptions(1, 10)),
		baseapp.SetOptimisticExecution(),
	)

	// Test closing app with all components
	err = app.Close()
	require.NoError(t, err, "Close() with all components should not error")
}