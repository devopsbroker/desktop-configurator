# DevOpsBroker
DevOpsBroker delivers enterprise-level software tools to maximize individual and organizational ability to deliver applications and services at high velocity

## Ubuntu 18.04 Desktop Configurator ![New Release](images/new-icon.png)

The DevOpsBroker Ubuntu 18.04 Desktop Configurator is a complete turn-key solution for configuring a fresh installation of Ubuntu 18.04 Desktop.

A complete list of features and installation instructions can be found [here](Bionic/doc/README.md).

### Current Release
**July 10th, 2019:** desktop-configurator 2.2.0 was released

### Installation Overview
1. Download the latest Ubuntu 18.04 Desktop ISO from [Ubuntu 18.04 Releases](http://releases.ubuntu.com/18.04/)

2. Install Ubuntu 18.04 Desktop

3. Download the latest release of [desktop-configurator](https://github.com/devopsbroker/desktop-configurator/releases/download/2.2.0/desktop-configurator_2.2.0_amd64.deb) and its [SHA256 Checksum](https://github.com/devopsbroker/desktop-configurator/releases/download/2.2.0/SHA256SUM)

4. Verify the **desktop-configurator** package against its SHA256 checksum

   * `sha256sum --check ./SHA256SUM`


5. Install the **desktop-configurator** package

   * `sudo apt install ./desktop-configurator_2.2.0_amd64.deb`


6. Configure your desktop

   * `sudo configure-desktop`


### Bugs / Feature Requests

Please submit any bugs or feature requests to GitHub by creating a [New issue](https://github.com/devopsbroker/desktop-configurator/issues)
