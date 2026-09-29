# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Quick Development Commands

```bash
# Build the project
flutter build

# Run on connected device/emulator
flutter run

# Run all tests
flutter test

# Run a single test file
flutter test test/path/to/specific_test.dart

# Analyze code for issues
flutter analyze

# Get dependencies
flutter pub get
```

## High-Level Architecture

### Data Layer (`inslate/lib/sources/`)
- **`transaction_source.dart`**: Abstract base class defining the transaction source interface
- **`sms_transaction_source.dart`**: SMS-specific implementation for receiving financial messages

### Business Logic Layer (`inslate/lib/services/`)
- **`permission_service.dart`**: Handles permission requests for accessing SMS and device features
- Centralizes transaction processing and validation

### Model Layer (`inslate/lib/models/`)
- **`raw_message.dart`**: Core data model representing financial transaction messages with metadata

### State Management
- Uses **Flutter Riverpod** (v2.6.1) for reactive state management
- Providers manage transaction lists, processing state, and UI state

### Platform Integration
- **`permission_handler`**: Manages Android/iOS permissions
- **`another_telephony`**: Handles SMS reading on Android (required for M-Pesa message parsing)

## Key Patterns

### Transaction Processing Flow
1. Permission request via `permission_service.dart`
2. SMS retrieval through `sms_transaction_source.dart`
3. Message classification and parsing using `raw_message.dart` model
4. State updates via Riverpod providers

### M-Pesa Integration
The project includes M-Pesa message parsers for:
- Send money
- Receive money  
- Paybill payments
- Buy goods (Lipa na M-Pesa)
- M-Shwari transactions

### Testing
- Widget tests in `test/`
- Unit tests for classifiers in `test/classifiers/`
- Test helpers in `test/helpers/`

## Important Files to Understand First
- `inslate/lib/models/raw_message.dart` - core transaction model
- `inslate/lib/sources/transaction_source.dart` - data source abstraction
- `inslate/analysis_options.yaml` - linting rules and analysis settings