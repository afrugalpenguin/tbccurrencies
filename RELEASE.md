# Release Checklist

Before each release:

- [ ] Update version in `TBCCurrencies.lua`
- [ ] Update `CHANGELOG.md`
- [ ] Commit with message: `chore(release): bump version to X.Y.Z`
- [ ] Create and push tag: `git tag vX.Y.Z && git push origin vX.Y.Z`

## Version Tagging Rules

Follow [Semantic Versioning](https://semver.org/):

| Type | When to use | Example |
|------|-------------|---------|
| **Major** (X.0.0) | Breaking changes | 1.0.0 → 2.0.0 |
| **Minor** (X.Y.0) | New features, new currencies | 1.0.0 → 1.1.0 |
| **Patch** (X.Y.Z) | Bug fixes, layout tweaks | 1.0.1 → 1.0.2 |

## Tag Format

Always prefix with `v`: `v1.0.0`
