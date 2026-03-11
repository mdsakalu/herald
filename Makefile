.PHONY: build-cli build-app install test clean

build-cli:
	swift build -c release

build-app: build-cli
	./scripts/build-app.sh

install:
	./scripts/install.sh

test:
	swift test

clean:
	swift package clean
	rm -rf .build/Herald.app
