# PURPOSE

## Problem Statement

Network infrastructure is invisible to the naked eye. Engineers and operators need a way to map, trace, and document the physical and logical paths that connect devices, services, and locations across a network topology. Currently there is no lightweight tool for creating and sharing visual network maps with geographic context and line-of-sight analysis between points.

## Target Users & Stakeholders

- **Network engineers** who need to document and visualize network paths
- **Infrastructure operators** who manage physical network topology
- **Technical teams** who need a shared reference for network mapping and visibility analysis
- **HelixTrace / Meshcore development team** at EGT Digital

## Value & Success Metrics

- Enables engineers to create and share visual network path maps
- Reduces time spent documenting network topology manually
- Provides line-of-sight visibility analysis between geographic network points
- Provides a single source of truth for network path information
- Success is measured by user adoption within engineering teams and the quality of maps created

## Non-Goals

- Real-time network monitoring or packet tracing
- Automated network discovery or scanning
- Integration with existing network management systems (NMS)
- Multi-tenant SaaS deployment (initially)
- Web or desktop platforms (mobile-first)

## Constraints

- Mobile-first Flutter application (iOS and Android)
- Depends on an external backend API (`trace-api.meshcore.bg`) for authentication, point management, trace path computation, and elevation data
- Uses `flutter_riverpod` for state management
- Supports light and dark themes with persistent user preference
- Configuration (API base URL) is user-configurable at runtime
- Map rendering depends on third-party tile providers (OSM, OpenTopoMap, Stamen, ESRI, CartoDB)

## System Role

HelixTrace is a mobile client that communicates with the HelixTrace backend API. It handles user authentication, point management (create, read, update, delete geographic markers), trace path visualization, and line-of-sight analysis between geographic points.

See the [Architecture Overview](docs/explanation/architecture-overview.md) for the full system context.

## Lifecycle Expectations

The application is in active development. Authentication, map display, point visualization, and line-of-sight analysis are complete. Point CRUD operations (create, update, delete) are supported by the API layer but do not yet have UI screens. The core data models and API integration layer are implemented for all features.