[![](https://github.com/fiji/fiji-builds/actions/workflows/build.yml/badge.svg)](https://github.com/fiji/fiji-builds/actions/workflows/build.yml)
[![](https://github.com/fiji/fiji-builds/actions/workflows/pyimagej-bundle.yml/badge.svg)](https://github.com/fiji/fiji-builds/actions/workflows/pyimagej-bundle.yml)

## Fiji Bundles

This repository creates the Fiji downloadable bundles available from:

* https://downloads.imagej.net/fiji/latest/
* https://downloads.imagej.net/fiji/stable/
* https://downloads.imagej.net/fiji/archive/latest/
* https://downloads.imagej.net/fiji/archive/stable/

## PyImageJ Bundles

This repository also builds **PyImageJ bundles** - complete, self-contained packages that include Fiji, Java runtime, and all cached dependencies needed for PyImageJ initialization. These bundles enable PyImageJ usage in environments with restricted internet access or where downloading from LOCI servers is problematic.

### What's in a PyImageJ Bundle

Each bundle (`pyimagej-YYYYMMDD.tar.gz`) contains:
- **Fiji installation** (latest build)
- **Java 21 runtime** (Zulu JDK, linux64)
- **Pre-populated .jgo cache** (Java dependency management)
- **Pre-populated .m2 repository** (Maven dependencies)

### How PyImageJ Bundles are Created

1. **Automatic builds**: Weekly checks (Mondays 6 AM UTC) compare the latest Fiji bundle timestamp with our most recent PyImageJ bundle
2. **Smart building**: Only builds when Fiji has been updated (avoids unnecessary rebuilds)
3. **Manual builds**: Can be triggered on-demand with a "force build" option
4. **Retention policy**: Keeps latest bundle + bundles older than 6 months (deletes intermediate versions)

### Why Use GitHub Releases

We use GitHub "releases" (not actual software releases) as a distribution mechanism because:
- **File hosting**: GitHub provides reliable, fast downloads for large bundles (~500MB-1GB)
- **Version management**: Date-based tags make it easy to reference specific bundles
- **No bandwidth limits**: Unlike repository storage, release assets have no download restrictions
- **LOCI server independence**: Eliminates dependency on LOCI infrastructure that may block certain IPs

### How to Use PyImageJ Bundles

Perfect for Google Colab, air-gapped environments, or any situation where internet access is limited:

```python
%%capture pyimagej_setup
import os

# Only process bundle if Fiji doesn't already exist
if not os.path.exists("Fiji"):
    print("Setting up PyImageJ bundle...")

    # Work in a safe bundle directory to avoid conflicts with existing caches
    bundle_dir = "pyimagej_bundle"
    original_dir = os.getcwd()

    # Create and enter bundle directory
    os.makedirs(bundle_dir, exist_ok=True)
    os.chdir(bundle_dir)

    # Download bundle (update as desired)
    bundle_name = "pyimagej-20250912.tar.gz"
    print("Downloading PyImageJ bundle...")
    !wget https://github.com/fiji/fiji-builds/releases/latest/download/{bundle_name}

    # Extract bundle
    print("Extracting bundle...")
    !tar -xzf {bundle_name}

    # Move Fiji and Java to working directory
    !mv Fiji ../
    !mv jdk-latest ../
    print("Moved Fiji and Java runtime to working directory")

    # Safely merge bundle caches with existing user caches
    print("Merging bundle caches with local caches...")

    # Merge .jgo cache
    !mkdir -p ~/.jgo
    !cp -r .jgo/* ~/.jgo/ || true
    print("Merged .jgo cache")

    # Merge .m2 cache
    !mkdir -p ~/.m2
    !cp -r .m2/* ~/.m2/ || true
    print("Merged .m2 cache")

    # Clean up bundle directory and return to original location
    os.chdir(original_dir)
    !rm -rf {bundle_dir}
    print("Bundle setup complete!")
else:
    print("Fiji already exists, skipping bundle setup")

# Set up Java environment
if "JAVA_HOME" not in os.environ:
    java_home = !find ./jdk-latest/linux64 -name "*jdk*" -type d
    os.environ['JAVA_HOME'] = java_home[0]
    print(f"Set JAVA_HOME to: {os.environ['JAVA_HOME']}")

# Install PyImageJ if not already installed
try:
    import imagej
    print("PyImageJ already installed")
except ImportError:
    print("Installing PyImageJ...")
    %pip install pyimagej
    import imagej

# Initialize PyImageJ (no further downloads needed!)
try:
    # Check if ImageJ is already initialized
    ij.getVersion()
    print(f"PyImageJ already initialized with ImageJ {ij.getVersion()}")
except NameError:
    # ij variable doesn't exist, safe to initialize
    ij = imagej.init('./Fiji', mode='headless')
    print(f"PyImageJ initialized with ImageJ {ij.getVersion()}")
except Exception as e:
    # ij exists but might be in bad state, reinitialize
    print(f"Reinitializing PyImageJ (previous state: {e})")
    ij = imagej.init('./Fiji', mode='headless')
    print(f"PyImageJ initialized with ImageJ {ij.getVersion()}")

if ij is not None:
    print("✅ PyImageJ is ready to use! The 'ij' variable contains your ImageJ instance.")

# If anything went wrong, you can inspect the setup output (in a new cell):
# pyimagej_setup.show()  # Shows all setup steps and any errors
```

### Available Bundles

Browse and download bundles from: https://github.com/fiji/fiji-builds/releases

- Latest bundle: Always contains the most recent Fiji build
- Stable bundles: Long-term releases (6+ months old) for reproducible environments
- Date-based naming: `pyimagej-YYYYMMDD` format for easy identification
