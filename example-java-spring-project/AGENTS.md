# AGENTS.md

This file contains guidelines and instructions for agentic coding agents operating in this Java Spring Boot project.

## Build, Lint, and Test Commands

### Building the Project
- `./gradlew build` - Builds the entire project with tests: compile, test, and package
- `./gradlew clean` - Clean builds
- `./gradlew bootJar` - Creates executable JAR file

### Running Tests
- `./gradlew test` - Run all tests in the project
- `./gradlew test --tests "*OpenCodeApplicationTests*"` - Run specific test class
- `./gradlew test --tests "*contextLoads*"` - Run a specific test method

### Linting and Code Quality
- The project uses Java with Spring Boot conventions
- No explicit linting commands defined in build.gradle
- Code style follows Google Java Style Guide (standard for Java projects)

## Code Style Guidelines

### Imports
- Standard Java imports at top of file
- Spring Boot auto-imports are allowed
- Organize imports alphabetically

### Formatting
- 4 spaces for indentation (no tabs)
- Maximum line width: 100 characters
- No trailing whitespace
- Blank lines between method declarations and classes

### Naming Conventions
- PascalCase for class names (e.g., OpenCodeApplication)
- camelCase for variables and methods (e.g., main, contextLoads)
- Constants in UPPER_CASE (e.g., MAX_SIZE)
- Package names in lowercase (e.g., io.github.suppierk.opencode)

### Types
- Use explicit type declarations when needed
- Prefer final for constants
- Use Spring annotations appropriately

### Error Handling
- Use standard Java exception handling
- Handle exceptions in main application flow
- No unchecked exceptions should propagate without handling

### Code Structure
- Main entry point: public static void main(String[] args)
- Test classes follow pattern: [ClassName]Tests with @SpringBootTest annotation
- Methods should be well-defined and focused on single responsibility

## Project Structure
- src/main/java/io/github/suppierk/opencode/OpenCodeApplication.java - Main class
- src/test/java/io/github/suppierk/opencode/OpenCodeApplicationTests.java - Test class
- build.gradle - Build configuration
- settings.gradle - Gradle settings

## Additional Guidelines for Agents

1. When modifying code, ensure it follows Spring Boot conventions
2. Maintain consistency with existing code style
3. For any new functionality, write appropriate unit tests
4. Follow the package structure when creating new classes
5. Use standard Java annotations and Spring Boot features appropriately

## Version Control
- Follow conventional commits for commit messages
- Keep changes focused and atomic

## Testing Guidelines
- All new code should include unit tests
- Test methods should follow naming conventions (e.g., methodUnderTest_StateUnderTest)
- Integration tests should verify component interactions
- Use @SpringBootTest annotation for integration testing
- Use @Test annotation for individual test methods