APP_NAME = TakeMi
BUILD_DIR = .build/release
APP_BUNDLE = $(APP_NAME).app
EXECUTABLE = $(BUILD_DIR)/$(APP_NAME)

all: build bundle

build:
	swift build -c release

bundle:
	mkdir -p $(APP_BUNDLE)/Contents/MacOS
	mkdir -p $(APP_BUNDLE)/Contents/Resources
	cp $(EXECUTABLE) $(APP_BUNDLE)/Contents/MacOS/
	cp -r $(BUILD_DIR)/TakeMi_TakeMi.bundle $(APP_BUNDLE)/Contents/MacOS/
	cp Info.plist $(APP_BUNDLE)/Contents/
	if [ -f AppIcon.icns ]; then cp AppIcon.icns $(APP_BUNDLE)/Contents/Resources/; fi
	@echo "App bundle created at $(APP_BUNDLE)"

clean:
	rm -rf .build $(APP_BUNDLE)

run: all
	open $(APP_BUNDLE)
