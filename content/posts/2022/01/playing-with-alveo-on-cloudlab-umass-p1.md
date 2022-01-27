---
title: Setting up Alveo FPGAs on Cloudlab - Part 1
date: 2022-01-30
author: Vikram Narayanan
aliases:
- '/fpga-programming/2022/01/27/setting-up-alveo-fpga-on-cloudlab-p1.html'
---

As a systems research team, we build operating systems, low-level software,
hack kernels and yet hardware programming always remained on the todo-list of "cool,
but haven't tried yet". When Cloudlab started introducing FPGA accelerators to
their testbed, we got excited and finally decided to give it a try.

Cloudlab is one of the publicly available testbeds for research. In all of our
projects, we carry out the whole development process on Cloudlab
infrastructure. Recently, UMass Amherst cluster started offering machines with
FPGA accelerator cards.

The official documentation of [Cloudlab](https://docs.cloudlab.us/hardware.html)
lists a variety of hardware nodes to choose from based on your needs. As of
this writing, the FPGA machines on UMass cluster is still not listed on this
documentation.

We set up an experiment with `fpga-alveo` hardware on UMass cluster. This
machine also has a fairly recent CPU [**Intel(R) Xeon(R) Gold
6226R**](https://ark.intel.com/content/www/us/en/ark/products/199347/intel-xeon-gold-6226r-processor-22m-cache-2-90-ghz.html).
Our experiment uses stock Ubuntu 18.04 LTS, which is recommended for all Xilinx software versioned `v2021.2`.

### Setting up Xilinx development environment

* The first step is to query the PCI bus for the presence of any Xilinx device.
  The accelerator cards would show up as two different physical functions (PFs),
  one for management (FPGA shell) and one for user programming. More details
  [here](https://xilinx.github.io/XRT/master/html/platforms.html)

```
sudo lspci -d 10ee:
3b:00.0 Processing accelerators: Xilinx Corporation Device 500c
3b:00.1 Processing accelerators: Xilinx Corporation Device 500d
```


* There is a bit of a chicken-and-egg problem in figuring out which hardware is
  connected to this machine. There has got to be a better way to figure out the
  type of hardware connected to your PCIe bus. But we were lazy and tried to do
  a quick search on _UMass + cloudlab + fpga_ to figure out what UMass people
  were planning to populate on their cluster and we get a
  [hit](https://massopen.cloud/wp-content/uploads/2020/04/Open-Cloud-Workshop-OCT.pptx-2.pdf).
  We optimistically assumed they went with the same hardware listed on their
  proposal, which was Alveo U280 acceleration card.

* From here on, things get accelerated a bit. Xilinx has a getting started page
  for each hardware that hosts the list of tools you would need to set up the
    environment. Here is the page for [Alveo
    U280](https://www.xilinx.com/products/boards-and-kits/alveo/u280.html#gettingStarted).

* We installed the debian packages for the following components that are
  available from the _Getting Started_ page. Installing with apt (i.e., `apt install xilinx_debian_files.deb`)
  should automatically install all the needed dependencies.
  - XRT (Xilinux Runtime)
  - Target Deployment platform

* After installing, the device can be validated using this command. It also
  performs a few tests on the hardware.

```
$ sudo /opt/xilinx/xrt/bin/xbutil validate -d 0
---------------------------------------------------------------------
INFO: Found 1 cards

INFO: Validating card[0]: xilinx_u280_xdma_201920_3
INFO: == Starting AUX power connector check:
INFO: == AUX power connector check PASSED
INFO: == Starting Power warning check:
INFO: == Power warning check PASSED
INFO: == Starting PCIE link check:
INFO: == PCIE link check PASSED
INFO: == Starting SC firmware version check:
INFO: == SC firmware version check PASSED
INFO: == Starting verify kernel test:
INFO: == verify kernel test PASSED
INFO: == Starting IOPS test:
Maximum IOPS: 84145 (hello)
INFO: == IOPS test PASSED
INFO: == Starting DMA test:
Host -> PCIe -> FPGA write bandwidth = 11262.153007 MB/s
Host <- PCIe <- FPGA read bandwidth = 11899.228409 MB/s
INFO: == DMA test PASSED
INFO: == Starting device memory bandwidth test:
...........
Maximum throughput: 43738 MB/s
INFO: == device memory bandwidth test PASSED
INFO: == Starting PCIE peer-to-peer test:
P2P BAR is not enabled. Skipping validation
INFO: == PCIE peer-to-peer test SKIPPED
INFO: == Starting memory-to-memory DMA test:
M2M is not available. Skipping validation
INFO: == memory-to-memory DMA test SKIPPED
INFO: == Starting host memory bandwidth test:
Host_mem is not available. Skipping validation
INFO: == host memory bandwidth test SKIPPED
INFO: Card[0] validated successfully.

INFO: All cards validated successfully.
```

* However, to design/program the FPGA, you would need Vitis hardware suite that is
  available for download behind a registration wall.

### Installables behind a registration wall

Below installables are available only after creating a Xilinx account.
  1) Development target platform
  2) Vitis Core Development Kit

* Even for a minimal installation, Vitis suite would take around 170 GB of disk
  space. As Umass cluster does not support attaching a datastore currently, we
  installed all the software in the project specific NFS filesystem that is
  available under `/proj/<your-project-name/`. Please consult with Cloudlab
  administrators before installing it in the shared NFS drive.


### PYNQ

[PYNQ](https://github.com/Xilinx/PYNQ) is an opensource library that provides a
python API for Xilinx platforms. Installing PYNQ is fairly trivial with `pip`.
However, one can follow advanced setup instructions (such as installing through
`Conda`) detailed
[here](https://pynq.readthedocs.io/en/v2.7.0/getting_started/alveo_getting_started.html)

### PYNQ in action

* PYNQ relies on XRT that we installed earlier. So, it's important to source
  the XRT environment before using the `pynq` python module.
```bash
source /opt/xilinx/xrt/setup.sh
```

```python
In [1]: import pynq

In [2]: pynq.Device.devices
Out[2]: [<pynq.pl_server.xrt_device.XrtDevice at 0x7fb8dd4549b0>]

In [3]: pynq.Device.devices[0].name
Out[3]: 'xilinx_u280_xdma_201920_3'
```

### Hello World - A vector addition on U280

* Vitis_Accel_Examples -
  [https://github.com/Xilinx/Vitis_Accel_Examples](https://github.com/Xilinx/Vitis_Accel_Examples)
  hosts a variety of examples that can be programmed on Vitis supported
  platforms. We followed this introductory
  [video](https://www.youtube.com/watch?v=uJ1RPbDkvJI) to run `hello_world`
  example.

* To build the examples, you need to source both the XRT and Vitis environment
  (Vitis environment brings in their c++ compiler `v++`).
```bash
source /opt/xilinx/xrt/setup.sh
source /opt/tools/Xilinx/Vitis/2021.2/settings64.sh
```

* (Likely) due to the Y2K22 bug, the above examples refuse to compile on version
  `2021.2`. The error would look similar to
  [this](https://support.xilinx.com/s/question/0D52E00006uzPZu/caught-tcl-error-error-2201031626-is-an-invalid-argument-please-specify-an-integer-value?language=en_US).

  - The workaround suggested in the above link is to use `faketime` package to
    force the date before _01 January, 2022_.

  - One can compile and test for three different `TARGETS` (`sw_emu`, `hw_emu`,
    and `hw`). More description is available on the introductory video linked
    above.

* Invoking `make all` with `TARGET=hw` would take a while to finish. It
  produces an `xclbin` file in the end that can be flashed onto the FPGA.
```
faketime '2021-12-31 12:00:00' make all TARGET=hw PLATFORM=xilinx_u280_xdma_201920_3  -j 32
...
<snip>
INFO: [v++ 60-2256] Packaging for hardware
INFO: [v++ 60-2460] Successfully copied a temporary xclbin to the output xclbin: /opt/Vitis_Accel_Examples/hello_world/./build_dir.hw.xilinx_u280_xdma_201920_3/vadd.xclbin
INFO: [v++ 60-2343] Use the vitis_analyzer tool to visualize and navigate the relevant reports. Run the following command.
    vitis_analyzer /opt/Vitis_Accel_Examples/hello_world/build_dir.hw.xilinx_u280_xdma_201920_3/vadd.xclbin.package_summary
INFO: [v++ 60-791] Total elapsed time: 0h 0m 20s
INFO: [v++ 60-1653] Closing dispatch client
```

* Example invocation (running `make test` with `TARGET=hw`)
```
faketime '2021-12-31 12:00:00' make test TARGET=hw PLATFORM=xilinx_u280_xdma_201920_3  -j 32
./hello_world ./build_dir.hw.xilinx_u280_xdma_201920_3/vadd.xclbin
Found Platform
Platform Name: Xilinx
INFO: Reading ./build_dir.hw.xilinx_u280_xdma_201920_3/vadd.xclbin
Loading: './build_dir.hw.xilinx_u280_xdma_201920_3/vadd.xclbin'
Trying to program device[0]: xilinx_u280_xdma_201920_3
Device[0]: program successful!
TEST PASSED
```

### Validating vector addition using PYNQ

* Let's validate the hello world vector addition example using PYNQ. We can
  use `pynq.Overlay` class to load the generated `xclbin` file.
```
In [4]: ol = pynq.Overlay('/opt/Vitis_Accel_Examples/hello_world/build_dir.hw.xilinx_u280_xdma_201920_3/vadd.xclbin')
```

* It is possible to access the kernel from the `xclbin` file. Our kernel
  (vector addition) is `vadd`. We can see the signature of the kernel.

```
In [8]: ol.vadd_1.signature
Out[8]: <Signature (in1:'void*', in2:'void*', out_r:'void*', size:'unsigned int')>
```

* Let's create input/output buffers to test the vadd kernel
```
# Allocate buffers
In [9]: in1 = pynq.allocate(32)

In [10]: in2 = pynq.allocate(32)

In [11]: out = pynq.allocate(32)

In [12]: import random

# Populate input data with random numbers
In [13]: for x in range(0, in1.size):
    ...:     in1[x] = random.randint(1, 512)
    ...:     in2[x] = random.randint(1, 512)
    ...:

In [14]: in1
Out[14]:
PynqBuffer([397, 409, 434,  70, 192, 335, 258, 213, 255, 459, 376, 306,
            102, 166, 323,  20, 129, 253, 396, 378, 247, 295, 381,   5,
            446, 217, 481, 140, 115, 285, 477,   5], dtype=uint32)

In [15]: in2
Out[15]:
PynqBuffer([243,  88, 497, 143, 347,  34, 319, 102, 197,  17,  45, 212,
             79, 473, 257, 188, 468, 466, 263, 170,  94, 171, 124,  36,
            454,  73, 172,  27,  50, 279, 381,  27], dtype=uint32)
```

* The input buffers need to be sync-ed to the device
```
In [16]: in1.sync_to_device()

In [17]: in2.sync_to_device()
```

* We can invoke the kernel on the inputs we created (`in1` and `in2`) by
  invoking the `call` method on the kernel.
```
In [18]: ol.vadd_1.call(in1, in2, out, 32)

```

* Finally, we can validate the output by syncing the `out` buffer back to the host.
```
In [19]: out
Out[19]:
PynqBuffer([0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
            0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0], dtype=uint32)

In [20]: out.sync_from_device()

In [21]: out
Out[21]:
PynqBuffer([640, 497, 931, 213, 539, 369, 577, 315, 452, 476, 421, 518,
            181, 639, 580, 208, 597, 719, 659, 548, 341, 466, 505,  41,
            900, 290, 653, 167, 165, 564, 858,  32], dtype=uint32)
```

### Revisiting the node

If you happen to swap out the node, just install the dependencies and also the
kernel modules necessary for accessing the Xilinx devices (`xocl.ko` and
`xclmgmt.ko`). The easiest way is to just re-install the XRT component from the
deb package which takes care of installing the kernel modules and other
dependencies.

In Part 2, we will create a Vivado project for Alveo U280 card directly from
Verilog sources.

#### Resources

* Alveo U280 getting started - https://www.xilinx.com/products/boards-and-kits/alveo/u280.html#gettingStarted

* PYNQ docs - https://pynq.readthedocs.io/en/v2.7.0/index.html
