# Feature Model Repository

This repository provides a virtual machine running [kconfigreader](https://github.com/ckaestne/kconfigreader), a tool for reading Kconfig files and converting them into feature model formulas for further reasoning.

## Getting Started

Clone recursively:

```
git clone --recurse-submodules git@github.com:ekuiter/feature-model-repository.git
```

Install [Vagrant](https://www.vagrantup.com/).

Run `vagrant up` inside this repository. This will also prompt you to install the `hashicorp/bionic64` box, the base system for the VM.

After `vagrant up`, use `vagrant ssh` to log on.

With `chmod +x /vagrant/eval.sh && /vagrant/eval.sh`, you can read feature models for Linux and other Kconfig-based projects.
The results are stored into the `models/` directory, resulting in (description taken from https://github.com/PettTo/Feature-Model-History-of-Linux):

```
*.rsf       Intermediate xml file format, created by KConfigReader (dumpconf). Contains raw dump of the original KConfig model file
*.features  Simple text file containing all feature names contained in the original variability model
*.model     Text file that contains boolean constraints, which represent the original KConfig model
*.dimacs    Text file that contains CNF constraints, which represent the original KConfig model. Created by KConfigReader by using Tseitin transformation.
 ```

**On the "Releases" page, you can download the feature models read by eval.sh.**

This is comparable to the models found at https://github.com/PettTo/Feature-Model-History-of-Linux, only that we had a different selection of projects and commits.
We also made some changes to dumpconf (the tool used to produce the input RSF file for kconfigreader), to allow for reading feature models for other projects and versions.
Specifically, we added support for E_CHOICE (treated as E_LIST), P_IMPLY (treated as P_SELECT), E_NONE, E_LTH, E_LEQ, E_GTH, E_GEQ (ignored).