# Makefile for twin installation

PREFIX ?= /usr/local
BINDIR = $(PREFIX)/bin

.PHONY: install uninstall clean test test-integration help

help:
	@echo "twin - Simple rsync wrapper for syncing directories"
	@echo ""
	@echo "Available targets:"
	@echo "  install         - Install twin to $(BINDIR)"
	@echo "  uninstall       - Remove twin from $(BINDIR)"
	@echo "  test            - Run unit tests"
	@echo "  test-integration - Run integration tests (requires SSH to localhost)"
	@echo "  clean           - Clean any temporary files"
	@echo "  help            - Show this help message"
	@echo ""
	@echo "To install to a different location, use: make install PREFIX=/your/path"

install:
	@echo "Installing twin to $(BINDIR)..."
	@mkdir -p $(BINDIR)
	@chmod +x twin twin-config
	@cp twin $(BINDIR)/twin
	@cp twin-config $(BINDIR)/twin-config
	@echo "Installation complete! twin is now available at $(BINDIR)/twin"
	@echo "Make sure $(BINDIR) is in your PATH."

uninstall:
	@echo "Removing twin from $(BINDIR)..."
	@rm -f $(BINDIR)/twin $(BINDIR)/twin-config
	@echo "Uninstall complete!"

clean:
	@echo "Nothing to clean"

test:
	@echo "Running unit tests..."
	@./test_twin.sh

test-integration:
	@echo "Running integration tests (requires SSH to localhost)..."
	@./test_integration.sh