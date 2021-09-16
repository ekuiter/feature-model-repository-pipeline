# kconfigreader VM

This repository provides a virtual machine running [kconfigreader](https://github.com/ckaestne/kconfigreader), a tool for reading Kconfig files and converting them into formulas for further reasoning.

## Getting Started

Clone recursively:

```
git clone --recurse-submodules git@github.com:ekuiter/kconfigreader-vm.git
```

Install [Vagrant](https://www.vagrantup.com/).

Run `vagrant up` inside this repository. This will also prompt you to install the
`ubuntu/trusty64` box, the base system for the VM.

After `vagrant up`, use `vagrant ssh` to log on, then `cd kconfigreader`.

With `chmod +x run.sh && ./run.sh v4.0 x86`, you can read the feature model for Linux v4.0 in the x86 architecture into the `models/` directory, resulting in (description taken from https://github.com/PettTo/Feature-Model-History-of-Linux):

```
*.rsf       Intermediate xml file format, created by KConfigReader (dumpconf). Contains raw dump of the original KConfig model file
*.features  Simple text file containing all feature names contained in the original variability model
*.model     Text file that contains boolean constraints, which represent the original KConfig model
*.dimacs    Text file that contains CNF constraints, which represent the original KConfig model. Created by KConfigReader by using Tseitin transformation.
 ```

With `chmod +x eval.sh && ./eval.sh`, you can read feature models for all Linux versions (based on Git tags).
Without modifications, kconfigreader can only read feature models for Linux v2.6.25-v4.15.

*On the "Releases" page, you can download the Linux feature model for all of these versions as read by kconfigreader.*
This is comparable to the models found at https://github.com/PettTo/Feature-Model-History-of-Linux, only that we had a different selection of commits (all tags).