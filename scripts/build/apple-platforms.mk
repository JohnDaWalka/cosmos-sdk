#!/usr/bin/make -f

# Apple platforms build targets for Cosmos SDK with Polkadot integration

# Rust targets for Apple platforms
IOS_TARGETS = aarch64-apple-ios aarch64-apple-ios-sim x86_64-apple-ios
WATCHOS_TARGETS = aarch64-apple-watchos aarch64-apple-watchos-sim x86_64-apple-watchos-sim  
TVOS_TARGETS = aarch64-apple-tvos aarch64-apple-tvos-sim x86_64-apple-tvos-sim
MACOS_TARGETS = x86_64-apple-darwin aarch64-apple-darwin

ALL_APPLE_TARGETS = $(IOS_TARGETS) $(WATCHOS_TARGETS) $(TVOS_TARGETS) $(MACOS_TARGETS)

# Output directories
APPLE_BUILD_DIR = $(BUILDDIR)/apple
IOS_BUILD_DIR = $(APPLE_BUILD_DIR)/ios
WATCHOS_BUILD_DIR = $(APPLE_BUILD_DIR)/watchos
TVOS_BUILD_DIR = $(APPLE_BUILD_DIR)/tvos
MACOS_BUILD_DIR = $(APPLE_BUILD_DIR)/macos

# Framework output
FRAMEWORK_DIR = $(APPLE_BUILD_DIR)/frameworks
XCFRAMEWORK_DIR = $(FRAMEWORK_DIR)/CosmosPolkadotSDK.xcframework

.PHONY: apple-platforms ios watchos tvos macos apple-clean apple-setup
.PHONY: install-rust-apple-targets install-cargo-lipo
.PHONY: build-ios build-watchos build-tvos build-macos
.PHONY: create-xcframework package-apple-sdk

#? apple-platforms: Build for all Apple platforms (iOS, watchOS, tvOS, macOS)
apple-platforms: apple-setup build-ios build-watchos build-tvos build-macos create-xcframework

#? apple-setup: Set up build environment for Apple platforms
apple-setup: install-rust-apple-targets install-cargo-lipo
	@echo "Setting up Apple platforms build environment..."
	@mkdir -p $(IOS_BUILD_DIR) $(WATCHOS_BUILD_DIR) $(TVOS_BUILD_DIR) $(MACOS_BUILD_DIR) $(FRAMEWORK_DIR)

#? install-rust-apple-targets: Install Rust targets for Apple platforms
install-rust-apple-targets:
	@echo "Installing Rust targets for Apple platforms..."
	@for target in $(ALL_APPLE_TARGETS); do \
		echo "Installing target: $$target"; \
		rustup target add $$target; \
	done

#? install-cargo-lipo: Install cargo-lipo for creating universal binaries
install-cargo-lipo:
	@echo "Installing cargo-lipo..."
	@cargo install cargo-lipo --quiet || true

#? build-ios: Build for iOS (device and simulator)
build-ios: apple-setup
	@echo "Building for iOS platforms..."
	@cd polkadot-compat/runtime && \
	for target in $(IOS_TARGETS); do \
		echo "Building for iOS target: $$target"; \
		case "$$target" in \
			*-sim) \
				cargo build --target $$target --release --no-default-features; \
				;; \
			*) \
				cargo build --target $$target --release --no-default-features; \
				;; \
		esac; \
	done
	@echo "Creating iOS universal binary..."
	@cd polkadot-compat/runtime && \
	cargo lipo --release --targets $(shell echo $(IOS_TARGETS) | tr ' ' ',') --output ../../$(IOS_BUILD_DIR)/libcosmos_polkadot_runtime.a

#? build-watchos: Build for watchOS (device and simulator) 
build-watchos: apple-setup
	@echo "Building for watchOS platforms..."
	@cd polkadot-compat/runtime && \
	for target in $(WATCHOS_TARGETS); do \
		echo "Building for watchOS target: $$target"; \
		cargo build --target $$target --release --no-default-features; \
	done
	@echo "Creating watchOS universal binary..."
	@cd polkadot-compat/runtime && \
	cargo lipo --release --targets $(shell echo $(WATCHOS_TARGETS) | tr ' ' ',') --output ../../$(WATCHOS_BUILD_DIR)/libcosmos_polkadot_runtime.a

#? build-tvos: Build for tvOS (device and simulator)
build-tvos: apple-setup
	@echo "Building for tvOS platforms..."
	@cd polkadot-compat/runtime && \
	for target in $(TVOS_TARGETS); do \
		echo "Building for tvOS target: $$target"; \
		cargo build --target $$target --release --no-default-features; \
	done  
	@echo "Creating tvOS universal binary..."
	@cd polkadot-compat/runtime && \
	cargo lipo --release --targets $(shell echo $(TVOS_TARGETS) | tr ' ' ',') --output ../../$(TVOS_BUILD_DIR)/libcosmos_polkadot_runtime.a

#? build-macos: Build for macOS (Intel and Apple Silicon)
build-macos: apple-setup  
	@echo "Building for macOS platforms..."
	@cd polkadot-compat/runtime && \
	for target in $(MACOS_TARGETS); do \
		echo "Building for macOS target: $$target"; \
		cargo build --target $$target --release; \
	done
	@echo "Creating macOS universal binary..."
	@cd polkadot-compat/runtime && \
	cargo lipo --release --targets $(shell echo $(MACOS_TARGETS) | tr ' ' ',') --output ../../$(MACOS_BUILD_DIR)/libcosmos_polkadot_runtime.a

#? create-xcframework: Create XCFramework bundle for distribution
create-xcframework: build-ios build-macos
	@echo "Creating XCFramework..."
	@mkdir -p $(XCFRAMEWORK_DIR)/ios-arm64_x86_64
	@mkdir -p $(XCFRAMEWORK_DIR)/macos-arm64_x86_64
	
	# Copy libraries
	@cp $(IOS_BUILD_DIR)/libcosmos_polkadot_runtime.a $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/
	@cp $(MACOS_BUILD_DIR)/libcosmos_polkadot_runtime.a $(XCFRAMEWORK_DIR)/macos-arm64_x86_64/
	
	# Create module map
	@echo "framework module CosmosPolkadotSDK {" > $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/module.modulemap
	@echo "  header \"cosmos_polkadot_runtime.h\"" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/module.modulemap  
	@echo "  export *" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/module.modulemap
	@echo "}" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/module.modulemap
	
	@cp $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/module.modulemap $(XCFRAMEWORK_DIR)/macos-arm64_x86_64/
	
	# Create C header file for bindings
	@echo "#ifndef COSMOS_POLKADOT_RUNTIME_H" > $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "#define COSMOS_POLKADOT_RUNTIME_H" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "#ifdef __cplusplus" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "extern \"C\" {" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "#endif" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "// Cosmos-Polkadot runtime interface" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "typedef struct CosmosPolkadotRuntime CosmosPolkadotRuntime;" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "// Initialize the runtime" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "CosmosPolkadotRuntime* cosmos_polkadot_runtime_init(void);" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "// Cleanup the runtime" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "void cosmos_polkadot_runtime_free(CosmosPolkadotRuntime* runtime);" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "#ifdef __cplusplus" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "}" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "#endif" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	@echo "#endif // COSMOS_POLKADOT_RUNTIME_H" >> $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h
	
	@cp $(XCFRAMEWORK_DIR)/ios-arm64_x86_64/cosmos_polkadot_runtime.h $(XCFRAMEWORK_DIR)/macos-arm64_x86_64/
	
	# Create Info.plist for XCFramework
	@echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>" > $(XCFRAMEWORK_DIR)/Info.plist
	@echo "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "<plist version=\"1.0\">" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "<dict>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "	<key>AvailableLibraries</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "	<array>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "		<dict>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>HeadersPath</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<string>Headers</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>LibraryIdentifier</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<string>ios-arm64_x86_64</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>LibraryPath</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<string>libcosmos_polkadot_runtime.a</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>SupportedArchitectures</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<array>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "				<string>arm64</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "				<string>x86_64</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			</array>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>SupportedPlatform</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<string>ios</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "		</dict>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "		<dict>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>HeadersPath</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<string>Headers</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>LibraryIdentifier</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<string>macos-arm64_x86_64</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>LibraryPath</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<string>libcosmos_polkadot_runtime.a</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>SupportedArchitectures</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<array>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "				<string>arm64</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "				<string>x86_64</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			</array>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<key>SupportedPlatform</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "			<string>macos</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "		</dict>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "	</array>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "	<key>CFBundlePackageType</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "	<string>XFWK</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "	<key>XCFrameworkFormatVersion</key>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "	<string>1.0</string>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "</dict>" >> $(XCFRAMEWORK_DIR)/Info.plist
	@echo "</plist>" >> $(XCFRAMEWORK_DIR)/Info.plist
	
	@echo "XCFramework created at: $(XCFRAMEWORK_DIR)"

#? package-apple-sdk: Create distributable package for Apple platforms
package-apple-sdk: create-xcframework
	@echo "Creating distributable package..."
	@cd $(FRAMEWORK_DIR) && tar -czf CosmosPolkadotSDK.tar.gz CosmosPolkadotSDK.xcframework
	@echo "Package created: $(FRAMEWORK_DIR)/CosmosPolkadotSDK.tar.gz"

#? test-apple-platforms: Run tests for Apple platform builds
test-apple-platforms:
	@echo "Running Apple platform tests..."
	@if command -v xcrun >/dev/null 2>&1; then \
		echo "Running iOS Simulator tests..."; \
		cd polkadot-compat/runtime && cargo test --target x86_64-apple-darwin --no-default-features; \
	else \
		echo "Xcode not available, skipping iOS tests"; \
	fi

#? apple-clean: Clean Apple platform build artifacts  
apple-clean:
	@echo "Cleaning Apple platform build artifacts..."
	@rm -rf $(APPLE_BUILD_DIR)
	@cd polkadot-compat && cargo clean

#? ios: Alias for build-ios
ios: build-ios

#? watchos: Alias for build-watchos  
watchos: build-watchos

#? tvos: Alias for build-tvos
tvos: build-tvos

#? macos: Alias for build-macos
macos: build-macos