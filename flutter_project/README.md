# Flutter Event Fetching App

This Flutter project is designed to fetch and display events from a remote API using the Dio package for HTTP requests. 

## Project Structure

```
flutter_project
├── lib
│   ├── main.dart               # Entry point of the application
│   ├── models
│   │   └── event.dart          # Model class for Event
│   ├── services
│   │   └── event_service.dart   # Service for fetching events
│   └── screens
│       └── event_screen.dart    # Screen to display events
├── pubspec.yaml                 # Project dependencies and configuration
└── README.md                    # Project documentation
```

## Setup Instructions

1. **Clone the repository:**
   ```
   git clone <repository-url>
   cd flutter_project
   ```

2. **Install dependencies:**
   Run the following command to install the required packages:
   ```
   flutter pub get
   ```

3. **Run the application:**
   Use the following command to run the app:
   ```
   flutter run
   ```

## Features

- Fetches events from a remote API.
- Displays a list of events with details such as name, date, and description.
- Utilizes Dio for efficient HTTP requests.

## Usage Guidelines

- The app starts by fetching events from the API when the home screen is loaded.
- Events are displayed in a scrollable list format.
- Ensure you have an active internet connection to fetch the events successfully.

## License

This project is open-source and available under the MIT License.