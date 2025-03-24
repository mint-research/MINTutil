# MINTutil Module Standardization Plan

## Overview

This document outlines the plan to standardize the module structure in MINTutil according to the following naming convention:

- global
- M01_installer
- M02_systeminfo
- M03_dummy

## Current Structure Analysis

The current MINTutil structure has these inconsistencies:

1. Global data is stored in "data/Globale Daten"
2. The Installer module exists with mixed naming (both "Installer" and "modul1" in different locations)
3. The SystemInfo module follows a consistent naming scheme
4. There's a "modul2" which is a placeholder "Under Construction" module

## Implementation Plan

### Phase 1: Directory Structure Updates

#### 1.1 Create/Rename Global Directories

- Rename "data/Globale Daten" to "data/global"
- Create corresponding directories in other locations if they don't exist:
  - meta/global
  - config/global
  - modules/global
  - docs/global

#### 1.2 Create/Rename M01_installer Directories

- Rename "data/Installer" and "data/modul1" to "data/M01_installer"
- Rename directories in other locations:
  - meta/Installer → meta/M01_installer
  - config/Installer → config/M01_installer
  - modules/Installer → modules/M01_installer
  - docs/Installer → docs/M01_installer

#### 1.3 Create/Rename M02_systeminfo Directories

- Rename "data/SystemInfo" to "data/M02_systeminfo"
- Rename directories in other locations:
  - meta/SystemInfo → meta/M02_systeminfo
  - config/SystemInfo → config/M02_systeminfo
  - modules/SystemInfo → modules/M02_systeminfo
  - docs/SystemInfo → docs/M02_systeminfo

#### 1.4 Create/Rename M03_dummy Directories

- Rename "data/modul2" to "data/M03_dummy"
- Rename directories in other locations:
  - meta/modul2 → meta/M03_dummy
  - config/modul2 → config/M03_dummy
  - modules/modul2 → modules/M03_dummy
  - docs/modul2 → docs/M03_dummy

### Phase 2: File Content Updates

#### 2.1 Update Module Script Files

- Update all path references in PowerShell scripts
- Update module initialization function names:
  - Initialize-Installer → Initialize-M01_installer
  - Initialize-SystemInfo → Initialize-M02_systeminfo
  - Initialize-modul2 → Initialize-M03_dummy
- Update any variables that reference module names

#### 2.2 Update Metadata Files

- Update module names, orders, and labels in meta.json files:
  - Set order values to match module numbers (M01=1, M02=2, M03=3)
  - Update corresponding modulinfo.json files

#### 2.3 Update UI Files

- Update any references to module names in XAML files
- Ensure IDs and references remain consistent with new naming

#### 2.4 Update Documentation Files

- Update module references in all documentation files
- Ensure documentation reflects the new structure

### Phase 3: Main Script Updates

- Update main.ps1 to properly handle the new module names
- Update path references in validate_mintutil.ps1

### Phase 4: Testing and Validation

- Run validate_mintutil.ps1 to verify proper structure
- Test each module individually to ensure functionality
- Test cross-module interactions

### Phase 5: Clean-up

- Remove any redundant or obsolete directories
- Clean up any temporary files created during migration

## Implementation Steps

For each module, we'll follow this process:

1. Create the new directory structure if it doesn't exist
2. Copy content from old directories to new ones
3. Update file contents with new path references and function names
4. Test and validate
5. Once verified, remove old directories

## Risks and Mitigations

- **Risk**: Loss of functionality during transition
  - **Mitigation**: Implement changes module by module with testing at each step

- **Risk**: Missing path references causing runtime errors
  - **Mitigation**: Thorough testing after each module update

- **Risk**: Incompatibilities between renamed modules
  - **Mitigation**: Comprehensive cross-module testing after all updates

## Conclusion

This standardization will improve maintainability and consistency across the MINTutil project while preserving all existing functionality.