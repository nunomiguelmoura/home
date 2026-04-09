# Digger

A .NET-based automated movie discovery and torrent management service that searches for movies on YTS (Your Torrent Site) and manages downloads via Transmission torrent client.

## Overview

Digger is a background service that:
- Automatically searches for new movies on YTS based on configurable criteria (genres, languages, quality, ratings)
- Manages torrent downloads through Transmission client
- Maintains a local SQLite database of discovered movies and their download status
- Enforces storage limits by skipping older movies when space limits are reached
- Retries failed downloads and manages torrent lifecycle (seeding, completing, archiving)

## Features

- **Automated Movie Discovery**: Continuously searches YTS for new movies matching your preferences
- **Smart Downloads**: Filters by quality (1080p, 2160p), minimum ratings, languages, and genres
- **Storage Management**: Automatically manages disk space by archiving older movies when limits are reached
- **Torrent Management**: Controls seeders, pending seeds, and completed torrents via Transmission RPC
- **Persistent State**: Tracks movie status and download progress in SQLite database
- **Configurable Retry Logic**: Automatically retries failed downloads with configurable retry limits
- **Docker Support**: Containerized deployment with Docker Compose

## Technology Stack

- **Language**: C# 10
- **.NET Framework**: .NET 10.0
- **Database**: SQLite with Entity Framework Core (EF Core 10.0.0)
- **Hosting**: .NET Worker Service
- **Container**: Docker + Docker Compose

## Project Structure

```
src/digger/
├── Digger/                          # Main Worker Service
│   ├── Program.cs                   # DI setup and host configuration
│   ├── Worker.cs                    # Main background service logic
│   ├── Dockerfile                   # Container configuration
│   ├── appsettings.json             # Configuration (YTS, Transmission, etc.)
│   └── Properties/launchSettings.json
├── Digger.Services/                 # Business logic layer
│   ├── Contracts/
│   │   ├── IYtsService.cs           # YTS API interface
│   │   └── ITransmissionService.cs  # Transmission RPC interface
│   └── Implementations/
│       ├── YtsService.cs            # YTS API implementation
│       └── TransmissionService.cs   # Transmission client implementation
├── Digger.Services.Models/          # Data transfer objects
│   └── Yts/
│       ├── YtsMovieModel.cs
│       ├── Movie.cs
│       ├── Torrent.cs
│       ├── Meta.cs
│       ├── Data.cs
│       └── YtsResponse.cs
└── Digger.Data.Common/              # Shared data models
    └── Enums/
        └── MovieStatus.cs           # Movie states (Pending, Downloading, Complete, etc.)

infra/
├── compose.yaml                     # Docker Compose configuration
└── (contains Nginx proxy manager, Frigate, and commented Digger service)
```

## Configuration

### appsettings.json

#### YTS Settings
```json
"Yts": {
  "ApiUrl": "https://yts.bz/api/v2/list_movies.json",
  "Parameters": {
    "quality": "2160p",           // Video quality
    "minimum_rating": "4",         // Minimum IMDB rating
    "sort_by": "year",
    "order_by": "desc",
    "limit": "50"
  },
  "YearsBack": 1,                 // Search movies from last N years
  "Genres": [...],                // Genres to search for
  "Languages": ["en", "pt"],      // Language preferences
  "MinimumSeeders": 10            // Minimum seeders for torrent
}
```

#### Transmission Settings
```json
"Transmission": {
  "ServerUrl": "http://transmission:9091/transmission/rpc",
  "User": "transmission",
  "Password": "Nullis!=0",
  "UseAuth": true
}
```

#### Service Settings
```json
"StopTime": 1,                              // Interval between searches (minutes)
"MaxAllocatedSpace": 750000000000,         // Max storage (750GB)
"MaxEnqueuedTorrents": 5,                  // Max concurrent downloads
"MaxEnqueuedRetries": 3                    // Retry attempts for failed downloads
```

## Setup & Installation

### Prerequisites
- .NET 10.0 SDK
- Docker & Docker Compose (for containerized deployment)
- Transmission torrent client (accessible at configured URL)

### Build
```bash
cd src/digger
dotnet build
```

### Run Locally
```bash
cd src/digger/Digger
dotnet run
```

### Docker Deployment

1. Uncomment the `digger` service in `infra/compose.yaml`:
```yaml
digger:
  build:
    context: ./digger
    dockerfile: Digger/Dockerfile
  container_name: digger
  depends_on:
    - transmission
  environment:
    Logging__Level__Default: Warning
  networks:
    services:
      ipv4_address: 10.52.0.3
  restart: unless-stopped
  volumes:
    - ${TRANSMISSION_DOWNLOADS_DIR:-.transmission/downloads}/movies:/downloads/movies:rw
    - ${DIGGER_DATA_DIR:-.digger/data}:/digger/data
```

2. Deploy with Docker Compose:
```bash
cd infra
docker-compose up -d
```

## Usage

The service runs continuously in the background, executing the following cycle:

1. **Digging for Movies**: Searches YTS API for new movies matching criteria
2. **Skipping Old Files**: Marks oldest downloaded movies as "Skipped" when storage limit is approached
3. **Syncing Downloads**: Updates movie status based on Transmission torrent states:
   - Seeding/PendingSeed → Complete
   - Stopped → Aborted
4. **Retrying Failed**: Retries failed downloads that haven't exceeded retry limit
5. **Wait**: Sleeps for configured interval before next cycle

### Movie Statuses

The service tracks movies through these states:
- **Pending**: Found but not yet downloading
- **Downloading**: Active torrent download
- **Seeding/PendingSeed**: Download complete, seeding for others
- **Complete**: Finished and archived
- **Skipped**: Marked for skipping due to storage limits
- **Failed/Aborted**: Download issues
- **Error**: Unexpected issues

## Dependencies

- `Microsoft.EntityFrameworkCore.Sqlite` - Database ORM
- `Microsoft.Extensions.Hosting` - Worker service hosting
- Internal: `Digger.Services`, `Digger.Data.Common`, `Digger.Services.Models`

## Troubleshooting

- Check logs in `appsettings.json` log level configuration
- Verify Transmission RPC connection and credentials
- Ensure YTS API is accessible
- Check disk space hasn't exceeded `MaxAllocatedSpace`

## License

TBD

