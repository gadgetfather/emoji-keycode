APP_NAME := EmojiKeycode
APP_BUNDLE := $(APP_NAME).app
BUILD_DIR := .build/release
BIN := $(BUILD_DIR)/$(APP_NAME)
RESOURCES_SRC := Sources/EmojiKeycode/Resources
INFO_PLIST := Info.plist

# Point swift/swift-test at the full Xcode toolchain (needed for XCTest, AppKit SDK).
export DEVELOPER_DIR ?= /Applications/Xcode.app/Contents/Developer

ICON_SRC := assets/AppIcon.png
ICON := assets/AppIcon.icns

.PHONY: all build test emoji-db icon app run clean

all: app

build:
	swift build -c release

test:
	swift test

emoji-db:
	bash scripts/build-emoji-db.sh

icon: $(ICON)

$(ICON): $(ICON_SRC) scripts/build-icon.sh
	bash scripts/build-icon.sh

app: build icon
	@rm -rf $(APP_BUNDLE)
	@mkdir -p $(APP_BUNDLE)/Contents/MacOS
	@mkdir -p $(APP_BUNDLE)/Contents/Resources
	@cp $(BIN) $(APP_BUNDLE)/Contents/MacOS/$(APP_NAME)
	@cp $(INFO_PLIST) $(APP_BUNDLE)/Contents/Info.plist
	@if [ -f "$(RESOURCES_SRC)/emojis.json" ]; then \
		cp $(RESOURCES_SRC)/emojis.json $(APP_BUNDLE)/Contents/Resources/emojis.json; \
	else \
		echo "warning: $(RESOURCES_SRC)/emojis.json not found; run 'make emoji-db' first"; \
	fi
	@if [ -f "$(ICON)" ]; then \
		cp $(ICON) $(APP_BUNDLE)/Contents/Resources/AppIcon.icns; \
	fi
	@touch $(APP_BUNDLE)
	@echo "Built $(APP_BUNDLE)"

run: app
	open ./$(APP_BUNDLE)

clean:
	rm -rf .build $(APP_BUNDLE)
