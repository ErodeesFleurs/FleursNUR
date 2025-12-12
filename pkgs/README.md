# Packages Directory

This directory contains all package definitions for the fleurs-nur repository.

## Auto-Discovery System

Packages are **automatically discovered** by the build system. Any subdirectory containing a `default.nix` file will be treated as a package and automatically exported.

## Adding a New Package

### Step 1: Create Package Directory

```bash
mkdir pkgs/my-awesome-package
```

### Step 2: Write default.nix

```bash
cat > pkgs/my-awesome-package/default.nix << 'EOF'
{
  stdenv,
  fetchFromGitHub,
  cmake,
  # Add your dependencies here
}:

stdenv.mkDerivation rec {
  pname = "my-awesome-package";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "someone";
    repo = "my-awesome-package";
    rev = "v${version}";
    hash = "sha256-AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA=";
  };

  nativeBuildInputs = [ cmake ];

  meta = with lib; {
    description = "An awesome package";
    homepage = "https://github.com/someone/my-awesome-package";
    license = licenses.mit;
    maintainers = with maintainers; [ /* your name */ ];
    platforms = platforms.linux;
  };
}
EOF
```

### Step 3: Test Your Package

```bash
# Build the package
nix build .#my-awesome-package

# Test it
./result/bin/my-awesome-package
```

That's it! No need to modify `default.nix` or any other file. The package is automatically discovered and available.

## Package Organization

### Simple Packages

For simple packages, just put a `default.nix` in the package directory:

```
pkgs/my-package/
└── default.nix
```

### Complex Packages

For packages with patches, additional files, or sub-packages:

```
pkgs/openstarbound/
├── default.nix           # Main package definition
├── patches/              # Patches to apply
│   └── CMakeLists.txt
└── README.md            # Package-specific documentation
```

### Shared Dependencies

If you need to share a package between multiple packages, create it as a standalone package:

```
pkgs/imgui/              # Shared by multiple packages
└── default.nix

pkgs/openstarbound/      # Uses imgui
└── default.nix          # Receives imgui as parameter
```

In the dependent package, just add the dependency to the function arguments:

```nix
{
  stdenv,
  imgui,  # Will be automatically provided by callPackage
  # ...
}:
```

## Best Practices

### 1. Use Proper Meta Attributes

Always include proper metadata:

```nix
meta = with lib; {
  description = "Short description";
  longDescription = ''
    Longer description if needed.
  '';
  homepage = "https://project-homepage.com";
  license = licenses.mit;  # or licenses.gpl3, etc.
  maintainers = [ /* maintainer info */ ];
  platforms = platforms.linux;  # or platforms.all, etc.
  broken = false;  # Set to true if package is broken
};
```

### 2. Pin Versions

Always specify exact versions and hashes:

```nix
version = "1.2.3";
src = fetchFromGitHub {
  # ...
  rev = "v${version}";  # or exact commit hash
  hash = "sha256-...";  # Use `nix-prefetch-url` or `nix flake prefetch`
};
```

### 3. Mark Broken Packages

If a package is temporarily broken, mark it:

```nix
meta = {
  broken = true;
  # ...
};
```

This prevents CI failures and clearly indicates the package status.

### 4. Follow Nixpkgs Conventions

- Use `pname` and `version` instead of `name`
- Use `nativeBuildInputs` for build-time dependencies
- Use `buildInputs` for runtime dependencies
- Use `propagatedBuildInputs` for dependencies that must be available to consumers

### 5. Document Package-Specific Details

If your package has special requirements or configuration, add a README.md:

```
pkgs/my-package/
├── default.nix
└── README.md
```

## Testing

### Build All Packages

```bash
nix flake check
```

### Build Specific Package

```bash
nix build .#my-package
```

### Enter Development Shell

```bash
nix develop .#my-package
```

## Troubleshooting

### Package Not Found

If your package isn't being discovered:

1. Ensure the directory name matches what you expect
2. Verify `default.nix` exists in the directory
3. Check for syntax errors: `nix eval .#my-package --raw`

### Dependency Issues

If you need a dependency that's not in nixpkgs:

1. Create it as a separate package in `pkgs/`
2. Reference it in your package's function arguments
3. The auto-discovery system will handle the rest

### Build Failures

Check the build log:

```bash
nix build .#my-package --print-build-logs
```

Or enter a build environment to debug:

```bash
nix develop .#my-package
```

## Examples

See existing packages for reference:

- **openstarbound**: Complex package with patches and multiple dependencies
- **imgui**: Library package used as a dependency
- **uudeck**: Simple binary package with wrapper script