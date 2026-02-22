## ADDED Requirements

### Requirement: Hello World endpoint
The system SHALL provide an endpoint that returns a JSON response with "message": "Hello, World!"

#### Scenario: Successful request
- **WHEN** client makes GET request to /api/hello-world
- **THEN** system responds with HTTP 200 OK and JSON content-type
- **AND** response body contains {"message": "Hello, World!"}

#### Scenario: Invalid request
- **WHEN** client makes request to endpoint with invalid parameters
- **THEN** system responds with HTTP 400 Bad Request

### Requirement: Response format
The system SHALL respond with proper HTTP status codes and content-type headers

#### Scenario: Response headers
- **WHEN** client makes GET request to /api/hello-world
- **THEN** system responds with Content-Type: application/json
- **AND** HTTP Status Code 200 OK
