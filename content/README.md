# PIH Lesotho Content Package

This module defines the Lesotho-specific [OpenMRS Initializer](https://github.com/mekomsolutions/openmrs-module-initializer) configuration. At build time, the contents of `configuration/` are assembled into a zip artifact published as `org.pih.openmrs:lesotho-content`.

This content package is merged with the shared [PIH EMR content](https://github.com/PIH/openmrs-config-pihemr) (`org.pih.openmrs:pihemr-content`) when the distribution is built.

## Configuration Structure

Configuration files live under `configuration/backend_configuration/` and are loaded by the OpenMRS Initializer module at startup.

| Directory | Purpose |
|---|---|
| `addresshierarchy/` | Address hierarchy entries for Lesotho |
| `autogenerationoptions/` | Auto-generation options for patient identifiers |
| `globalproperties/` | OpenMRS global property overrides |
| `idgen/` | Identifier source definitions |
| `locations/` | Facility and location definitions |
| `locationtagmaps/` | Maps locations to location tags |
| `metadatermmappings/` | Maps concepts/metadata to standard terms |
| `patientidentifiertypes/` | Patient identifier type definitions |
| `pih/` | PIH-specific configuration (radiology constants, etc.) |

## content.properties

`content.properties` provides the content package name and version (interpolated from the Maven project at build time), and defines key UUID constants used across the configuration:

| Property | Description |
|---|---|
| `var.patientIdentifierType.emrId.uuid` | UUID of the EMR ID patient identifier type |
