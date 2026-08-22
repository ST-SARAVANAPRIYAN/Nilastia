qml_module(nilastia-internal
    URI Nilastia.Internal
    SOURCES
        circularbuffer.cpp
        circularindicatormanager.cpp
        linearindicatormanager.cpp
        sparklineitem.cpp
        visualiserbars.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Network
)
