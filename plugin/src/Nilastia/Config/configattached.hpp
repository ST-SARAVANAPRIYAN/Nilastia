#pragma once

#include "config.hpp"

#include <qquickattachedpropertypropagator.h>

namespace nilastia::config {

class Config : public QQuickAttachedPropertyPropagator, public QQmlParserStatus {
    Q_OBJECT
    Q_INTERFACES(QQmlParserStatus)
    QML_ELEMENT
    QML_UNCREATABLE("")
    QML_ATTACHED(Config)
    Q_MOC_INCLUDE("appearanceconfig.hpp")
    Q_MOC_INCLUDE("backgroundconfig.hpp")
    Q_MOC_INCLUDE("barconfig.hpp")
    Q_MOC_INCLUDE("borderconfig.hpp")
    Q_MOC_INCLUDE("dashboardconfig.hpp")
    Q_MOC_INCLUDE("generalconfig.hpp")
    Q_MOC_INCLUDE("launcherconfig.hpp")
    Q_MOC_INCLUDE("lockconfig.hpp")
    Q_MOC_INCLUDE("nexusconfig.hpp")
    Q_MOC_INCLUDE("notifsconfig.hpp")
    Q_MOC_INCLUDE("osdconfig.hpp")
    Q_MOC_INCLUDE("serviceconfig.hpp")
    Q_MOC_INCLUDE("sessionconfig.hpp")
    Q_MOC_INCLUDE("sidebarconfig.hpp")
    Q_MOC_INCLUDE("userpaths.hpp")
    Q_MOC_INCLUDE("utilitiesconfig.hpp")
    Q_MOC_INCLUDE("winfoconfig.hpp")

    Q_PROPERTY(QString screen READ screen WRITE inheritScreen NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::AppearanceConfig* appearance READ appearance NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::GeneralConfig* general READ general NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::BackgroundConfig* background READ background NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::BarConfig* bar READ bar NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::BorderConfig* border READ border NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::DashboardConfig* dashboard READ dashboard NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::LauncherConfig* launcher READ launcher NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::LockConfig* lock READ lock NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::NexusConfig* nexus READ nexus NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::NotifsConfig* notifs READ notifs NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::OsdConfig* osd READ osd NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::ServiceConfig* services READ services NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::SessionConfig* session READ session NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::SidebarConfig* sidebar READ sidebar NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::UtilitiesConfig* utilities READ utilities NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::WInfoConfig* winfo READ winfo NOTIFY sourceChanged)
    Q_PROPERTY(const nilastia::config::UserPaths* paths READ paths NOTIFY sourceChanged)

public:
    explicit Config(QObject* parent = nullptr);

    [[nodiscard]] QString screen() const;
    void inheritScreen(const QString& screen);

    [[nodiscard]] const AppearanceConfig* appearance() const;
    [[nodiscard]] const GeneralConfig* general() const;
    [[nodiscard]] const BackgroundConfig* background() const;
    [[nodiscard]] const BarConfig* bar() const;
    [[nodiscard]] const BorderConfig* border() const;
    [[nodiscard]] const DashboardConfig* dashboard() const;
    [[nodiscard]] const LauncherConfig* launcher() const;
    [[nodiscard]] const LockConfig* lock() const;
    [[nodiscard]] const NexusConfig* nexus() const;
    [[nodiscard]] const NotifsConfig* notifs() const;
    [[nodiscard]] const OsdConfig* osd() const;
    [[nodiscard]] const ServiceConfig* services() const;
    [[nodiscard]] const SessionConfig* session() const;
    [[nodiscard]] const SidebarConfig* sidebar() const;
    [[nodiscard]] const UtilitiesConfig* utilities() const;
    [[nodiscard]] const WInfoConfig* winfo() const;
    [[nodiscard]] const UserPaths* paths() const;

    [[nodiscard]] Q_INVOKABLE static GlobalConfig* forScreen(const QString& screen);

    static Config* qmlAttachedProperties(QObject* object);

signals:
    void sourceChanged();

protected:
    void attachedParentChange(
        QQuickAttachedPropertyPropagator* newParent, QQuickAttachedPropertyPropagator* oldParent) override;

private:
    void classBegin() override;
    void componentComplete() override;

    void propagateScreen();

    bool m_complete = false;
    QString m_screen;
    GlobalConfig* m_config = nullptr;
};

} // namespace nilastia::config
