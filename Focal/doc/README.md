# DevOpsBroker Ubuntu 20.04 Desktop Configurator

The DevOpsBroker Ubuntu 20.04 Desktop Configurator is a complete turn-key solution for configuring a fresh installation of Ubuntu 20.04 Desktop.

The following tasks are performed by the Configurator:

- Configures IPv4 firewall and IPv6 firewall using nftables
- Installs all DevOpsBroker system administration and user utilities
- Installs a number of useful applications, libraries and utilities
- Installs any available proprietary drivers
- Configures and optimizes the filesystem
- Performs Linux kernel tuning optimizations
- Performs general system configuration
- Configures the fastest APT sources mirror
- Configures and optimizes GRUB
- Manages DevOpsBroker configuration files (e.g. ansi.conf)
- Tunes network cards based on individual connections (i.e. Wi-Fi networks)
- Performs Samba configuration and optimization
- Configures systemwide security configuration
- Configures the Disk I/O schedulers
- Configure systemd-resolved DNS servers
- Performs user configuration
- Complete solution for setting up a Samba server

## Install Ubuntu 20.04 Desktop

### Download Ubuntu 20.04 Desktop

First thing to do is download and install a fresh copy of Ubuntu 20.04 Desktop. The latest ISO images can be found at:

[Ubuntu 20.04 Focal Fossa Downloads](https://releases.ubuntu.com/20.04/)

Download the 64-bit ISO image to take full advantage of the hardware inside your PC or laptop. Save the ISO file to the Downloads directory.

![Image of 64-bit ISO](ubuntu-focal-desktop-amd64-iso.png)

### Create Bootable USB Drive

For each scenario below, you will need:
- A 2GB or larger USB drive
- The Ubuntu 20.04 Desktop ISO file

#### From Windows

1. Download [Rufus](https://rufus.akeo.ie/), a free and open-source tool to create bootable USB drives
2. Launch Rufus
   * Insert USB drive
   * Select USB drive in the Device field
   * Boot Selection
     - Select the Ubuntu 20.04 Desktop ISO file
   * Partition Scheme
     - Select **MBR**
   * Target System
     - Select **BIOS or UEFI**
   * Click **Start**

Once Rufus completes the ISO image writing process, you can now install Ubuntu 20.04 Desktop from the USB drive.

#### From Ubuntu

1. Insert USB drive
2. Launch Starup Disk Creator
   * Search for 'Startup Disk Creator' from either **Activities** or **Show Applications**
3. Select the Ubuntu 20.04 Desktop ISO file
4. Select the USB drive
5. Click **Make Startup Disk**
6. Confirm the USB drive chosen is correct

Once Startup Disk Creator completes the ISO image writing process, you can now install Ubuntu 20.04 Desktop from the USB drive.

### Enable UEFI Boot in BIOS

Again, in order to take full advantage of your machine hardware, you will want to enable UEFI booting before installing Ubuntu.

Every manufacturer is different when it comes to enabling UEFI booting in BIOS. For instance, on my Gigabyte motherboard, I must **disable** CSM Support in order to enable UEFI booting.

![Enable UEFI](bios-disable-csm.png)

Check the motherboard documentation to find the specifics on enabling UEFI booting for your machine.

### EFI System Partition Configuration

The EFI booting architecture requires a specialized partition configuration in order to work properly.

1. Create a custom partition scheme from **Installation type**
   * Choose **Something else** from the Installation type menu

![Image of Ubuntu Installation Type](ubuntu-desktop-installation-type.png)

2. Create an empty partition table (**WARNING: Will erase everything on the disk**)
   * Click on the **New Parition Table...** button and then select **Continue**

![Image of Create New Empty Partition Table](create-empty-partition-table.png)

3. Create a swap partition
   * Click on the **+** button and then configure with the appropriate size for your machine

![Image of Create Swap Partition Table](create-swap-partition.png)

4. Create an EFI System partition
   * A 100MB partition size is more than sufficient

![Image of Create EFI System Partition Table](create-efi-system-partition.png)

5. Create a /boot partition
   * Make 1000MB partition size with ext4 file system

![Image of Create /boot Partition Table](create-boot-partition.png)

6. Create the / partition
   * Use the rest of the disk for the root partition size with the XFS file system

![Image of Create Root Partition Table](create-root-partition.png)

7. Write all changes to disk
   * Click on **Install Now** button and then select **Continue**

![Image of Write Changes to Disk](write-changes-to-disk.png)
