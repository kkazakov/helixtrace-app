# Documentation Index

Welcome to the HelixTrace documentation. This index links to every document in the set.

## Overview

- [README.md](../README.md) — Project orientation, build/run/test commands, quick start
- [PURPOSE.md](../PURPOSE.md) — Business intent, value, stakeholders, constraints

## Architecture

- [Architecture Overview](explanation/architecture-overview.md) — System context, containers, data flow, cross-cutting concerns

## Component Deep-Dives

| Component | Description |
|---|---|
| [App Entry & Routing](explanation/app-entry-routing.md) | App initialization, GoRouter configuration, authentication shell |
| [Authentication](explanation/authentication.md) | Login and registration screens, auth state machine |
| [Data Layer](explanation/data-layer.md) | API service, auth service, repositories, data models |
| [State Management](explanation/state-management.md) | Riverpod providers, dependency injection chain, auth and theme state |
| [Core Infrastructure](explanation/core-infrastructure.md) | Storage service, theming, validators, constants, reusable widgets |

## No ADRs Yet

This project has not yet created architecture decision records. When architecturally significant decisions are made, create them in `docs/architecture/adr/`.

## No API Reference Yet

When the project exposes formal interfaces (REST, gRPC, CLI), document them in `docs/reference/`.
