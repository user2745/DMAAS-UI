# Activities Rebrand — TODO

## Deferred Items

### Package Rename (Next Refactor)
- [ ] Rename `name: DMAAS` → `name: activities` in `pubspec.yaml`
- [ ] Update all `import 'package:DMAAS/...'` references across the codebase
- [ ] Update test imports
- [ ] Verify build after rename

### Firebase & Bundle IDs (Future)
- [ ] Update iOS bundle ID from `ai.predictionlabs.dmaasUi` to new Activities ID
- [ ] Update Firebase project or create new one under Activities branding
- [ ] Update Android `applicationId` if applicable

### Hardcoded Colors (Cleanup)
- [x] `main_navigation_page.dart` — replace remaining `Color(0xFF...)` with `AppTheme` constants
- [x] Audit all files in `lib/src/features/` for hardcoded color hex values
- [x] Replace all instances with `AppTheme` constant references

### Brand Assets
- [x] Replace default Flutter favicon with Activities logo
- [x] Replace `web/icons/Icon-192.png` and `Icon-512.png` with Activities icon
- [x] Replace maskable icons
- [x] Add Activities logo PNG to `assets/images/` directory
- [x] Update `pubspec.yaml` to declare assets directory
- [x] Use logo asset in login page and navigation bar

### Git / CI
- [ ] Update GitHub repo name/description if desired
- [ ] Update any CI/CD references to old name
