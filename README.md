# Libretro Core Metadata & Buildbot Audit Pipeline

An automated metadata parser and report generator that cross-references local Libretro core info files, documentation indexes, and Libretro Buildbot binary availability across platforms and architectures.

## Features

- **Automated Data Fetching**: Retrieves the latest `.info` file archives and Libretro documentation indexes.
- **Buildbot Auditing**: Scans nightly Buildbot indexes across multiple platforms (Android, Apple, Linux, Nintendo, PlayStation, Windows, etc.).
- **Data Standardization**: Converts raw Buildbot indexes into normalized JSON data (`cache/core-index.json`).
- **Comprehensive Markdown Reporting**: Generates interactive cross-reference tables and OS/architecture support matrices.

## Published Reports (`docs/`)

> [!NOTE]
> All Markdown files inside the `docs/` directory are **automatically generated** on a daily schedule via GitHub Actions running `generate.sh`. Any manual changes made to files in `docs/` will be overwritten.

