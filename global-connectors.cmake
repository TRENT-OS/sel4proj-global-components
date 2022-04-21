#
# Copyright 2018, Data61, CSIRO (ABN 41 687 119 230)
# Copyright 2021, HENSOLDT Cyber GmbH
#
# SPDX-License-Identifier: BSD-2-Clause
#

cmake_minimum_required(VERSION 3.8.2)

CAmkESAddImportPath(interfaces plat_interfaces/${KernelPlatform})
CAmkESAddTemplatesPath(templates)

foreach(
    connector
    IN
    ITEMS
    seL4RPCCallSignal
    seL4RPCDataport
    seL4RPCDataportSignal
    seL4RPCNoThreads
    seL4GlobalAsynch
    seL4GlobalAsynchCallback
    seL4MessageQueue
    seL4RPCOverMultiSharedData
    seL4SharedDataWithCaps
    seL4GPIOServer
    seL4Ethdriver
)
    DeclareCAmkESConnector(${connector} GENERATE)
endforeach()


#-------------------------------------------------------------------------------
DeclareCAmkESConnector(seL4RPCCallSignalNoThreads GENERATE TYPE seL4RPCCallSignal)
DeclareCAmkESConnector(seL4RPCDataportNoThreads GENERATE TYPE seL4RPCDataport)

DeclareCAmkESConnector(seL4GlobalAsynchHardwareInterrupt GENERATE_TO SYMMETRIC NO_HEADER)

DeclareCAmkESConnector(seL4DTBHardwareThreadless GENERATE_TO SYMMETRIC NO_HEADER)
DeclareCAmkESConnector(seL4DTBHWThreadless GENERATE_TO SYMMETRIC TYPE seL4DTBHardwareThreadless )

DeclareCAmkESConnector(seL4VirtQueues GENERATE_FROM)

DeclareCAmkESConnector(seL4TimeServer GENERATE TYPE seL4RPCCallSignal)

DeclareCAmkESConnector(seL4SerialServer GENERATE TYPE seL4RPCDataportSignal)

DeclareCAmkESConnector(seL4PicoServer GENERATE TYPE seL4RPCDataport)
DeclareCAmkESConnector(seL4PicoServerSignal GENERATE TYPE seL4RPCCallSignal)



