#include "settingmeta.hpp"

#include "settingsobject.hpp"

namespace nilastia::plugins {

Q_LOGGING_CATEGORY(lcPluginSettings, "nilastia.plugins.settings", QtInfoMsg)

SettingMeta::SettingMeta(QObject* parent)
    : QObject(parent) {}

void SettingMeta::setTarget(const QQmlProperty& property) {
    m_key = property.name();

    if (auto* const settings = qobject_cast<SettingsObject*>(property.object()))
        settings->registerMeta(m_key, this);
    else
        qCWarning(
            lcPluginSettings, "SettingMeta on '%s' must target a property of a SettingsObject", qUtf8Printable(m_key));
}

QString SettingMeta::key() const {
    return m_key;
}

} // namespace nilastia::plugins
