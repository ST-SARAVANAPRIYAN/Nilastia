#pragma once

#include "configobject.hpp"

#include <qstring.h>

namespace nilastia::config {

using Qt::StringLiterals::operator""_s;

class OsdConfig : public ConfigObject {
    Q_OBJECT
    QML_ANONYMOUS

    CONFIG_PROPERTY(bool, enabled, true)
    CONFIG_PROPERTY(bool, showOnHover, false)
    CONFIG_PROPERTY(QString, revealMode, u"keys"_s)
    CONFIG_PROPERTY(int, hideDelay, 2000)
    CONFIG_PROPERTY(bool, enableBrightness, true)
    CONFIG_PROPERTY(bool, enableMicrophone, false)

public:
    explicit OsdConfig(QObject* parent = nullptr)
        : ConfigObject(parent) {}
};

} // namespace nilastia::config
