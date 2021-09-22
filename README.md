# Feature Model Repository

This repository provides feature models for several open-source projects based on the Kconfig language for variability modeling.
The feature models are created with [kconfigreader](https://github.com/ckaestne/kconfigreader) (a tool for reading Kconfig files and converting them into feature model formulas for further reasoning) and [Kmax/Kclause](https://github.com/paulgazz/kmax) (a collection of analysis tools for Kconfig and Kbuild constraints).
For improved reproducibility, both tools are set up and run in virtual machines using Vagrant (kconfigreader in Ubuntu 14.04 because of incompabilities between Java and Scala in newer versions).
Besides creating a public repository with large feature models, the idea of this project is also that you can change the scripts according to your own needs (e.g., projects/versions/commits) and automate most of the steps needed to set up and run kconfigreader and Kmax.

**You can freely access and download the feature models produced by this pipeline at: https://cloud.ovgu.de/s/pkD3By6bp8cTDLr**

## Getting Started

First, clone this repository:

```
git clone https://github.com/ekuiter/feature-model-repository.git
```

Install [Vagrant](https://www.vagrantup.com/) and [VirtualBox](https://www.virtualbox.org/), then run `vagrant up` inside this repository to set up both kconfigreader and Kmax.
After `vagrant up`, use `vagrant ssh <reader>` to log on to the VM (`<reader>` being `kconfigreader` or `kmax`).
In case that `vagrant up` fails with `error retrieving required libraries` for Scala, this can be fixed by re-running the setup script with `vagrant ssh kconfigreader` and `source /vagrant/setup_kconfigreader.sh`.
In case that this fails due to line endings (which can happen with Git on Windows), fix the line endings and re-run the setup script with `vagrant ssh kconfigreader` and `sudo apt-get update && sudo apt-get install dos2unix && find /vagrant -type f -exec dos2unix {} \; && /vagrant/setup_kconfigreader.sh`.

With `source /vagrant/read_models.sh <reader>`, you can read feature models for several versions of Linux and other Kconfig-based projects (this process can be monitored in less detail with `tail -f data/log_<reader>.txt`).
The results are stored into the `data/models/` directory in several formats (description taken from https://github.com/PettTo/Feature-Model-History-of-Linux):

```
*.rsf       Intermediate xml file format, created by KConfigReader (dumpconf). Contains raw dump of the original KConfig model file
*.features  Simple text file containing all feature names contained in the original variability model
*.model     Text file that contains boolean constraints, which represent the original KConfig model
*.dimacs    Text file that contains CNF constraints, which represent the original KConfig model. Created by KConfigReader by using Tseitin transformation.
 ```

The resulting models are comparable to those found at https://github.com/PettTo/Feature-Model-History-of-Linux and https://bitbucket.org/tberger/variability-models/src/master/kconfig/, only that we have a different selection of projects and commits.
We also made some changes to dumpconf (the tool used to produce the input RSF file for kconfigreader) and kextractor (a similar tool used by Kmax), to allow for reading feature models for other projects and versions.
Specifically, we added support for E_CHOICE (treated as E_LIST), P_IMPLY (treated as P_SELECT), E_NONE, E_LTH, E_LEQ, E_GTH, E_GEQ (ignored).
We also fixed some other bugs to allow reading feature models for other projects as well.
All compiled dumpconf/kextractor binaries are stored in the `data/c-bindings/` directory for later reuse.