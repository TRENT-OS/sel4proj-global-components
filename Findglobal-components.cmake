#
# Copyright 2019, Data61, CSIRO (ABN 41 687 119 230)
# Copyright 2022, HENSOLDT Cyber GmbH
#
# SPDX-License-Identifier: BSD-2-Clause
#

set(GLOBAL_COMPONENTS_DIR "${CMAKE_CURRENT_LIST_DIR}" CACHE STRING "")
set(GLOBAL_COMPONENTS_PATH "${CMAKE_CURRENT_LIST_DIR}/global-components.cmake" CACHE STRING "")
mark_as_advanced(GLOBAL_COMPONENTS_DIR GLOBAL_COMPONENTS_PATH)

function(global_components_import_connectors)
    CAmkESAddImportPath("interfaces" "plat_interfaces/${KernelPlatform}")
    CAmkESAddTemplatesPath("templates")

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
endfunction()

# Usage: import_from_global_components(<comp1> <comp2> ...)
function(import_from_global_components)
    CAmkESAddImportPath("components" "plat_components/${KernelPlatform}")
    foreach(comp IN LISTS ARGV)
        add_subdirectory("${GLOBAL_COMPONENTS_DIR}/${comp}" "${comp}")
    endforeach()
endfunction()

function(global_components_import_project)
    import_from_global_components(
        "remote-drivers/picotcp-ethernet-async2"
        "remote-drivers/picotcp-socket-sync"
        "components/modules/fdt-bind-driver"
        "components/modules/dynamic-untyped-allocators"
        "components/modules/single-threaded"
        "components/modules/x86-iospace-dma"
        "components/modules/picotcp-base"
        "components/BenchUtiliz"
        "components/ClockServer"
        "components/Ethdriver"
        "components/FileServer"
        "components/GPIOMUXServer"
        "components/PCIConfigIO"
        "components/PicoServer"
        "components/ResetServer"
        "components/RTC"
        "components/SerialServer"
        "components/TimeServer"
        "components/VirtQueue"
        "plat_components/tx2/BPMPServer"
    )
endfunction()

include(FindPackageHandleStandardArgs)
FIND_PACKAGE_HANDLE_STANDARD_ARGS(
    global-components
    DEFAULT_MSG
    GLOBAL_COMPONENTS_DIR
    GLOBAL_COMPONENTS_PATH
)
