# Weather App Backlog

Feature backlog populated by `/start-project` and managed via `/eck:select-feature`.

| Key                          | Feature                      | Description                                                                                                | Size | Priority | Status  |
| ---------------------------- | ---------------------------- | ---------------------------------------------------------------------------------------------------------- | ---- | -------- | ------- |
| WA-2                         | Weather Lookup               | City search returning current conditions (temperature, description, humidity) via GET /api/weather/:city   | M    | P1       | Done    |
| current-weather-conditions   | Current Weather Conditions   | Display real-time current conditions for a searched city, surfacing all available weather data fields      | M    | P1       | Backlog |
| 5-day-forecast               | 5-Day Forecast               | Show a 5-day daily forecast for the searched location with high/low temps and condition summaries          | M    | P2       | Backlog |
| unit-toggle                  | Unit Toggle                  | Switch between Celsius and Fahrenheit display; persist preference in localStorage                          | S    | P2       | Backlog |
| real-weather-api-integration | Real Weather API Integration | Replace in-memory stub data with a live weather API (e.g. OpenWeatherMap); add service layer and TTL cache | L    | P3       | Backlog |

> Use `/eck:create-feature` to add new features to the backlog.
> Use `/eck:select-feature` to activate a backlog feature for development.
