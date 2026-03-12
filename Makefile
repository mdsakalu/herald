.PHONY: build-cli build-app install clean

build-cli:
	swift build -c release

build-app: build-cli
	./scripts/build-app.sh

install:
	./scripts/install.sh

clean:
	swift package clean
	rm -rf .build/Herald.app
