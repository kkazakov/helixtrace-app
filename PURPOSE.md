# PURPOSE

## Problem Statement

Network infrastructure is invisible to the naked eye. Engineers and operators need a way to map, trace, and document the physical and logical paths that connect devices, services, and locations across a network topology. Currently there is no lightweight tool for creating and sharing visual network maps with geographic context.

## Target Users & Stakeholders

- **Network engineers** who need to document and visualize network paths
- **Infrastructure operators** who manage physical network topology
- **Technical teams** who need a shared reference for network mapping
- **HelixTrace / Meshcore development team** at EGT Digital

## Value & Success Metrics

- Enables engineers to create and share visual network path maps
- Reduces time spent documenting network topology manually
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
- Depends on an external backend API (`trace-api.meshcore.bg`) for authentication, point management, and trace path computation
- Uses `flutter_riverpod` for state management
- Supports light and dark themes with persistent user preference
- Configuration (API base URL) is user-configurable at runtime

## System Role

HelixTrace is a mobile client that communicates with the HelixTrace backend API. It handles user authentication, point management (create, read, update, delete geographic markers), and trace path visualization.

See the [Architecture Overview](docs/explanation/architecture-overview.md) for the full system context.

## Lifecycle Expectations

The application is in early development. The authentication flow is complete. The map screen is a placeholder awaiting actual mapping functionality. The core data models (points, trace paths, categories, elevation) are defined and the API integration layer is implemented, but the visual presentation layer for maps and traces remains to be built.
