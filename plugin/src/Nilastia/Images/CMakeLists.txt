qml_module(nilastia-images
    URI Nilastia.Images
    SOURCES
        cachingimageprovider.cpp
        imagecacher.cpp
        iutils.cpp
    LIBRARIES
        Qt::Gui
        Qt::Quick
        Qt::Concurrent
)
