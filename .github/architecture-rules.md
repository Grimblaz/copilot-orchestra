# Architecture Rules

<!-- TODO: Delete this block when done -->
> **Setup**: Replace all `<!-- TODO: ... -->` markers. See `examples/` for complete filled-in references (spring-boot-microservice, nodejs-typescript, python).

These rules define the structural constraints for this project. All agents and developers must follow them.

## Layer Structure

<!-- TODO: Define your layers and their responsibilities. Use a table like this one, then customize it. A simple 3-layer (controllers/services/data) works fine for most projects.

| Layer | Responsibility | Allowed Dependencies |
|-------|---------------|---------------------|
| **Controller** | HTTP handling, routing | Service, DTO |
| **Service** | Business logic | Repository, Domain |
| **Repository** | Data access | Domain / Entity |

-->

## Dependency Rules

### Allowed

<!-- TODO: List the dependency directions that are explicitly permitted. Use code comments to show examples in your language. See `examples/` for complete filled-in references (spring-boot-microservice, nodejs-typescript, python). -->

### Forbidden

<!-- TODO: List the dependency directions that are explicitly forbidden. Example:
- Controllers must NOT import Repository classes directly — go through Service
- Domain/Entity objects must NOT depend on framework annotations
-->

## Testing Rules

<!-- TODO: Describe your testing approach per layer. Examples:
- Unit tests: test Service and Repository layers in isolation with mocks
- Integration tests: use an in-memory or containerized database for Repository tests
- E2E tests: test Controller layer via HTTP with full application context
-->

## File & Naming Conventions

<!-- TODO: Specify naming patterns for files, classes, and functions in each layer. Examples:
- Controllers: `*Controller.ts` in `src/controllers/`
- Services: `*Service.ts` in `src/services/`
- Tests: `*.test.ts` co-located with source files
-->
