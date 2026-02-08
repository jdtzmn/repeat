DESTINATION ?= platform=iOS Simulator,name=iPhone 17 Pro

lint:
	mint run swiftlint

lint-format:
	mint run swiftformat . --lint

format:
	mint run swiftformat .

test:
	xcodebuild test -project Repeat.xcodeproj -scheme Repeat -destination "$(DESTINATION)"

.PHONY: lint lint-format format test
