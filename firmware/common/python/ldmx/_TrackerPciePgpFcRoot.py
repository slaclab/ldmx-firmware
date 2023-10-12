#!/usr/bin/env python3
##############################################################################
## This file is part of 'LDMX'.
## It is subject to the license terms in the LICENSE.txt file found in the
## top-level directory of this distribution and at:
##    https://confluence.slac.stanford.edu/display/ppareg/LICENSE.html.
## No part of 'LDMX', including this file,
## may be copied, modified, propagated, or distributed except according to
## the terms contained in the LICENSE.txt file.
##############################################################################

import rogue
import pyrogue as pr
import pyrogue.interfaces.simulation

import axipcie

import ldmx

import argparse

class TrackerPciePgpFcRoot(pr.Root):
    def __init__(
            self,
            dev = '/dev/datadev_0',
            sim = False,
            numLanes = 1,
            **kwargs):
        super().__init__(**kwargs)

        # Create PCIE memory mapped interface
        if sim:
            self.memMap = rogue.interfaces.memory.TcpClient('localhost', 11000)
        else:
#            self.memMap = pyrogue.interfaces.simulation.MemEmulate()
            self.memMap = rogue.hardware.axi.AxiMemMap(dev,)

        self.addInterface(self.memMap)

        # Add the PCIe core device to base
        self.add(axipcie.AxiPcieCore(
            offset      = 0x00000000,
            memBase     = self.memMap,
            numDmaLanes = numLanes,
            expand      = True,
            sim         = sim,
        ))

        self.add(ldmx.PgpFc(
            offset   = 0x00800000,
            memBase  = self.memMap,
            numQuads = numLanes,
            expand   = True))

class TrackerPciePgpFcArgParser(argparse.ArgumentParser):
    def __init__(self, **kwargs):
        super().__init__(**kwargs)

        # Add arguments
        self.add_argument(
            "--dev",
            type     = str,
            required = False,
            default  = '/dev/datadev_0',
            help     = "path to device driver",
        )

        self.add_argument(
            "--sim",
            action = 'store_true',
            default = False)

        self.add_argument(
            "--numLanes",
            "-l",
            type     = int,
            required = False,
            default  = 1,
            help     = "# of DMA Lanes (same as Transceiver Quads)",
        )
        
        self.add_argument(
            "--pollEn",
            action = 'store_true',
            default  = False,
            help     = "Enable auto-polling",
        )

        self.add_argument(
            "--initRead",
            action = 'store_true',
            default  = False,
            help     = "Enable read all variables at start",
        )
