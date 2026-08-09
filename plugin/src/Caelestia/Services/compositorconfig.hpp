#pragma once

#include <qobject.h>
#include <qqmlintegration.h>
#include <qvariant.h>
#include <qstring.h>

namespace caelestia::services {

class Compositor : public QObject {
    Q_OBJECT
    QML_ELEMENT
    QML_SINGLETON

    // Layout
    Q_PROPERTY(int gaps READ gaps WRITE setGaps NOTIFY gapsChanged)
    Q_PROPERTY(QString center_focused_column READ centerFocusedColumn WRITE setCenterFocusedColumn NOTIFY centerFocusedColumnChanged)
    Q_PROPERTY(bool always_center_single_column READ alwaysCenterSingleColumn WRITE setAlwaysCenterSingleColumn NOTIFY alwaysCenterSingleColumnChanged)
    Q_PROPERTY(qreal default_column_width READ defaultColumnWidth WRITE setDefaultColumnWidth NOTIFY defaultColumnWidthChanged)
    
    Q_PROPERTY(int focus_ring_width READ focusRingWidth WRITE setFocusRingWidth NOTIFY focusRingWidthChanged)
    Q_PROPERTY(QString focus_ring_active READ focusRingActive WRITE setFocusRingActive NOTIFY focusRingActiveChanged)
    Q_PROPERTY(QString focus_ring_inactive READ focusRingInactive WRITE setFocusRingInactive NOTIFY focusRingInactiveChanged)
    
    Q_PROPERTY(bool border_enabled READ borderEnabled WRITE setBorderEnabled NOTIFY borderEnabledChanged)
    Q_PROPERTY(int border_width READ borderWidth WRITE setBorderWidth NOTIFY borderWidthChanged)
    Q_PROPERTY(QString border_active READ borderActive WRITE setBorderActive NOTIFY borderActiveChanged)
    Q_PROPERTY(QString border_inactive READ borderInactive WRITE setBorderInactive NOTIFY borderInactiveChanged)

    Q_PROPERTY(bool shadow_enabled READ shadowEnabled WRITE setShadowEnabled NOTIFY shadowEnabledChanged)
    Q_PROPERTY(int shadow_softness READ shadowSoftness WRITE setShadowSoftness NOTIFY shadowSoftnessChanged)
    Q_PROPERTY(int shadow_spread READ shadowSpread WRITE setShadowSpread NOTIFY shadowSpreadChanged)
    Q_PROPERTY(QString shadow_color READ shadowColor WRITE setShadowColor NOTIFY shadowColorChanged)

    Q_PROPERTY(qreal overview_zoom READ overviewZoom WRITE setOverviewZoom NOTIFY overviewZoomChanged)

    // Input
    Q_PROPERTY(QString kb_layout READ kbLayout WRITE setKbLayout NOTIFY kbLayoutChanged)
    Q_PROPERTY(int kb_repeat_delay READ kbRepeatDelay WRITE setKbRepeatDelay NOTIFY kbRepeatDelayChanged)
    Q_PROPERTY(int kb_repeat_rate READ kbRepeatRate WRITE setKbRepeatRate NOTIFY kbRepeatRateChanged)
    
    Q_PROPERTY(bool touchpad_tap READ touchpadTap WRITE setTouchpadTap NOTIFY touchpadTapChanged)
    Q_PROPERTY(bool touchpad_natural_scroll READ touchpadNaturalScroll WRITE setTouchpadNaturalScroll NOTIFY touchpadNaturalScrollChanged)
    Q_PROPERTY(qreal touchpad_accel_speed READ touchpadAccelSpeed WRITE setTouchpadAccelSpeed NOTIFY touchpadAccelSpeedChanged)
    Q_PROPERTY(QString touchpad_click_method READ touchpadClickMethod WRITE setTouchpadClickMethod NOTIFY touchpadClickMethodChanged)
    
    Q_PROPERTY(QString mouse_accel_profile READ mouseAccelProfile WRITE setMouseAccelProfile NOTIFY mouseAccelProfileChanged)
    Q_PROPERTY(qreal mouse_accel_speed READ mouseAccelSpeed WRITE setMouseAccelSpeed NOTIFY mouseAccelSpeedChanged)

    Q_PROPERTY(bool warp_mouse_to_focus READ warpMouseToFocus WRITE setWarpMouseToFocus NOTIFY warpMouseToFocusChanged)
    Q_PROPERTY(bool focus_follows_mouse READ focusFollowsMouse WRITE setFocusFollowsMouse NOTIFY focusFollowsMouseChanged)

    Q_PROPERTY(QString cursor_theme READ cursorTheme WRITE setCursorTheme NOTIFY cursorThemeChanged)
    Q_PROPERTY(int cursor_size READ cursorSize WRITE setCursorSize NOTIFY cursorSizeChanged)
    Q_PROPERTY(bool cursor_hide_when_typing READ cursorHideWhenTyping WRITE setCursorHideWhenTyping NOTIFY cursorHideWhenTypingChanged)

    // Animations
    Q_PROPERTY(bool animations_off READ animationsOff WRITE setAnimationsOff NOTIFY animationsOffChanged)
    Q_PROPERTY(qreal animations_slowdown READ animationsSlowdown WRITE setAnimationsSlowdown NOTIFY animationsSlowdownChanged)

    Q_PROPERTY(qreal ws_damping READ wsDamping WRITE setWsDamping NOTIFY wsDampingChanged)
    Q_PROPERTY(qreal ws_stiffness READ wsStiffness WRITE setWsStiffness NOTIFY wsStiffnessChanged)
    Q_PROPERTY(qreal win_open_damping READ winOpenDamping WRITE setWinOpenDamping NOTIFY winOpenDampingChanged)
    Q_PROPERTY(qreal win_open_stiffness READ winOpenStiffness WRITE setWinOpenStiffness NOTIFY winOpenStiffnessChanged)
    Q_PROPERTY(qreal win_close_damping READ winCloseDamping WRITE setWinCloseDamping NOTIFY winCloseDampingChanged)
    Q_PROPERTY(qreal win_close_stiffness READ winCloseStiffness WRITE setWinCloseStiffness NOTIFY winCloseStiffnessChanged)
    Q_PROPERTY(qreal resize_damping READ resizeDamping WRITE setResizeDamping NOTIFY resizeDampingChanged)
    Q_PROPERTY(qreal resize_stiffness READ resizeStiffness WRITE setResizeStiffness NOTIFY resizeStiffnessChanged)

    // New properties (Blur & Transparency & CSD)
    Q_PROPERTY(bool prefer_no_csd READ preferNoCsd WRITE setPreferNoCsd NOTIFY preferNoCsdChanged)
    Q_PROPERTY(int blur_passes READ blurPasses WRITE setBlurPasses NOTIFY blurPassesChanged)
    Q_PROPERTY(qreal blur_offset READ blurOffset WRITE setBlurOffset NOTIFY blurOffsetChanged)
    Q_PROPERTY(qreal blur_noise READ blurNoise WRITE setBlurNoise NOTIFY blurNoiseChanged)
    Q_PROPERTY(qreal blur_saturation READ blurSaturation WRITE setBlurSaturation NOTIFY blurSaturationChanged)

    Q_PROPERTY(qreal active_opacity READ activeOpacity WRITE setActiveOpacity NOTIFY activeOpacityChanged)
    Q_PROPERTY(qreal inactive_opacity READ inactiveOpacity WRITE setInactiveOpacity NOTIFY inactiveOpacityChanged)
    Q_PROPERTY(bool window_blur_enabled READ windowBlurEnabled WRITE setWindowBlurEnabled NOTIFY windowBlurEnabledChanged)
    Q_PROPERTY(bool layer_blur_enabled READ layerBlurEnabled WRITE setLayerBlurEnabled NOTIFY layerBlurEnabledChanged)
    Q_PROPERTY(bool blur_xray READ blurXray WRITE setBlurXray NOTIFY blurXrayChanged)
    Q_PROPERTY(qreal shell_blur_noise READ shellBlurNoise WRITE setShellBlurNoise NOTIFY shellBlurNoiseChanged)
    Q_PROPERTY(qreal shell_blur_saturation READ shellBlurSaturation WRITE setShellBlurSaturation NOTIFY shellBlurSaturationChanged)
    Q_PROPERTY(int corner_radius READ cornerRadius WRITE setCornerRadius NOTIFY cornerRadiusChanged)
    Q_PROPERTY(bool clip_to_geometry READ clipToGeometry WRITE setClipToGeometry NOTIFY clipToGeometryChanged)
    Q_PROPERTY(bool empty_workspace_above_first READ emptyWorkspaceAboveFirst WRITE setEmptyWorkspaceAboveFirst NOTIFY emptyWorkspaceAboveFirstChanged)
    Q_PROPERTY(QString default_column_display READ defaultColumnDisplay WRITE setDefaultColumnDisplay NOTIFY defaultColumnDisplayChanged)
    Q_PROPERTY(QString opacity_exclusions READ opacityExclusions WRITE setOpacityExclusions NOTIFY opacityExclusionsChanged)

public:
    explicit Compositor(QObject* parent = nullptr);

    Q_INVOKABLE void load();
    Q_INVOKABLE void saveValue(const QString& key, const QVariant& value);

    // Getters and Setters
    int gaps() const { return m_gaps; }
    void setGaps(int v) { if (m_gaps != v) { m_gaps = v; emit gapsChanged(); } }

    QString centerFocusedColumn() const { return m_center_focused_column; }
    void setCenterFocusedColumn(const QString& v) { if (m_center_focused_column != v) { m_center_focused_column = v; emit centerFocusedColumnChanged(); } }

    bool alwaysCenterSingleColumn() const { return m_always_center_single_column; }
    void setAlwaysCenterSingleColumn(bool v) { if (m_always_center_single_column != v) { m_always_center_single_column = v; emit alwaysCenterSingleColumnChanged(); } }

    qreal defaultColumnWidth() const { return m_default_column_width; }
    void setDefaultColumnWidth(qreal v) { if (m_default_column_width != v) { m_default_column_width = v; emit defaultColumnWidthChanged(); } }

    int focusRingWidth() const { return m_focus_ring_width; }
    void setFocusRingWidth(int v) { if (m_focus_ring_width != v) { m_focus_ring_width = v; emit focusRingWidthChanged(); } }

    QString focusRingActive() const { return m_focus_ring_active; }
    void setFocusRingActive(const QString& v) { if (m_focus_ring_active != v) { m_focus_ring_active = v; emit focusRingActiveChanged(); } }

    QString focusRingInactive() const { return m_focus_ring_inactive; }
    void setFocusRingInactive(const QString& v) { if (m_focus_ring_inactive != v) { m_focus_ring_inactive = v; emit focusRingInactiveChanged(); } }

    bool borderEnabled() const { return m_border_enabled; }
    void setBorderEnabled(bool v) { if (m_border_enabled != v) { m_border_enabled = v; emit borderEnabledChanged(); } }

    int borderWidth() const { return m_border_width; }
    void setBorderWidth(int v) { if (m_border_width != v) { m_border_width = v; emit borderWidthChanged(); } }

    QString borderActive() const { return m_border_active; }
    void setBorderActive(const QString& v) { if (m_border_active != v) { m_border_active = v; emit borderActiveChanged(); } }

    QString borderInactive() const { return m_border_inactive; }
    void setBorderInactive(const QString& v) { if (m_border_inactive != v) { m_border_inactive = v; emit borderInactiveChanged(); } }

    bool shadowEnabled() const { return m_shadow_enabled; }
    void setShadowEnabled(bool v) { if (m_shadow_enabled != v) { m_shadow_enabled = v; emit shadowEnabledChanged(); } }

    int shadowSoftness() const { return m_shadow_softness; }
    void setShadowSoftness(int v) { if (m_shadow_softness != v) { m_shadow_softness = v; emit shadowSoftnessChanged(); } }

    int shadowSpread() const { return m_shadow_spread; }
    void setShadowSpread(int v) { if (m_shadow_spread != v) { m_shadow_spread = v; emit shadowSpreadChanged(); } }

    QString shadowColor() const { return m_shadow_color; }
    void setShadowColor(const QString& v) { if (m_shadow_color != v) { m_shadow_color = v; emit shadowColorChanged(); } }

    qreal overviewZoom() const { return m_overview_zoom; }
    void setOverviewZoom(qreal v) { if (m_overview_zoom != v) { m_overview_zoom = v; emit overviewZoomChanged(); } }

    QString kbLayout() const { return m_kb_layout; }
    void setKbLayout(const QString& v) { if (m_kb_layout != v) { m_kb_layout = v; emit kbLayoutChanged(); } }

    int kbRepeatDelay() const { return m_kb_repeat_delay; }
    void setKbRepeatDelay(int v) { if (m_kb_repeat_delay != v) { m_kb_repeat_delay = v; emit kbRepeatDelayChanged(); } }

    int kbRepeatRate() const { return m_kb_repeat_rate; }
    void setKbRepeatRate(int v) { if (m_kb_repeat_rate != v) { m_kb_repeat_rate = v; emit kbRepeatRateChanged(); } }

    bool touchpadTap() const { return m_touchpad_tap; }
    void setTouchpadTap(bool v) { if (m_touchpad_tap != v) { m_touchpad_tap = v; emit touchpadTapChanged(); } }

    bool touchpadNaturalScroll() const { return m_touchpad_natural_scroll; }
    void setTouchpadNaturalScroll(bool v) { if (m_touchpad_natural_scroll != v) { m_touchpad_natural_scroll = v; emit touchpadNaturalScrollChanged(); } }

    qreal touchpadAccelSpeed() const { return m_touchpad_accel_speed; }
    void setTouchpadAccelSpeed(qreal v) { if (m_touchpad_accel_speed != v) { m_touchpad_accel_speed = v; emit touchpadAccelSpeedChanged(); } }

    QString touchpadClickMethod() const { return m_touchpad_click_method; }
    void setTouchpadClickMethod(const QString& v) { if (m_touchpad_click_method != v) { m_touchpad_click_method = v; emit touchpadClickMethodChanged(); } }

    QString mouseAccelProfile() const { return m_mouse_accel_profile; }
    void setMouseAccelProfile(const QString& v) { if (m_mouse_accel_profile != v) { m_mouse_accel_profile = v; emit mouseAccelProfileChanged(); } }

    qreal mouseAccelSpeed() const { return m_mouse_accel_speed; }
    void setMouseAccelSpeed(qreal v) { if (m_mouse_accel_speed != v) { m_mouse_accel_speed = v; emit mouseAccelSpeedChanged(); } }

    bool warpMouseToFocus() const { return m_warp_mouse_to_focus; }
    void setWarpMouseToFocus(bool v) { if (m_warp_mouse_to_focus != v) { m_warp_mouse_to_focus = v; emit warpMouseToFocusChanged(); } }

    bool focusFollowsMouse() const { return m_focus_follows_mouse; }
    void setFocusFollowsMouse(bool v) { if (m_focus_follows_mouse != v) { m_focus_follows_mouse = v; emit focusFollowsMouseChanged(); } }

    QString cursorTheme() const { return m_cursor_theme; }
    void setCursorTheme(const QString& v) { if (m_cursor_theme != v) { m_cursor_theme = v; emit cursorThemeChanged(); } }

    int cursorSize() const { return m_cursor_size; }
    void setCursorSize(int v) { if (m_cursor_size != v) { m_cursor_size = v; emit cursorSizeChanged(); } }

    bool cursorHideWhenTyping() const { return m_cursor_hide_when_typing; }
    void setCursorHideWhenTyping(bool v) { if (m_cursor_hide_when_typing != v) { m_cursor_hide_when_typing = v; emit cursorHideWhenTypingChanged(); } }

    bool animationsOff() const { return m_animations_off; }
    void setAnimationsOff(bool v) { if (m_animations_off != v) { m_animations_off = v; emit animationsOffChanged(); } }

    qreal animationsSlowdown() const { return m_animations_slowdown; }
    void setAnimationsSlowdown(qreal v) { if (m_animations_slowdown != v) { m_animations_slowdown = v; emit animationsSlowdownChanged(); } }

    qreal wsDamping() const { return m_ws_damping; }
    void setWsDamping(qreal v) { if (m_ws_damping != v) { m_ws_damping = v; emit wsDampingChanged(); } }

    qreal wsStiffness() const { return m_ws_stiffness; }
    void setWsStiffness(qreal v) { if (m_ws_stiffness != v) { m_ws_stiffness = v; emit wsStiffnessChanged(); } }

    qreal winOpenDamping() const { return m_win_open_damping; }
    void setWinOpenDamping(qreal v) { if (m_win_open_damping != v) { m_win_open_damping = v; emit winOpenDampingChanged(); } }

    qreal winOpenStiffness() const { return m_win_open_stiffness; }
    void setWinOpenStiffness(qreal v) { if (m_win_open_stiffness != v) { m_win_open_stiffness = v; emit winOpenStiffnessChanged(); } }

    qreal winCloseDamping() const { return m_win_close_damping; }
    void setWinCloseDamping(qreal v) { if (m_win_close_damping != v) { m_win_close_damping = v; emit winCloseDampingChanged(); } }

    qreal winCloseStiffness() const { return m_win_close_stiffness; }
    void setWinCloseStiffness(qreal v) { if (m_win_close_stiffness != v) { m_win_close_stiffness = v; emit winCloseStiffnessChanged(); } }

    qreal resizeDamping() const { return m_resize_damping; }
    void setResizeDamping(qreal v) { if (m_resize_damping != v) { m_resize_damping = v; emit resizeDampingChanged(); } }

    qreal resizeStiffness() const { return m_resize_stiffness; }
    void setResizeStiffness(qreal v) { if (m_resize_stiffness != v) { m_resize_stiffness = v; emit resizeStiffnessChanged(); } }

    // Getters and Setters for new properties
    bool preferNoCsd() const { return m_prefer_no_csd; }
    void setPreferNoCsd(bool v) { if (m_prefer_no_csd != v) { m_prefer_no_csd = v; emit preferNoCsdChanged(); } }

    int blurPasses() const { return m_blur_passes; }
    void setBlurPasses(int v) { if (m_blur_passes != v) { m_blur_passes = v; emit blurPassesChanged(); } }

    qreal blurOffset() const { return m_blur_offset; }
    void setBlurOffset(qreal v) { if (m_blur_offset != v) { m_blur_offset = v; emit blurOffsetChanged(); } }

    qreal blurNoise() const { return m_blur_noise; }
    void setBlurNoise(qreal v) { if (m_blur_noise != v) { m_blur_noise = v; emit blurNoiseChanged(); } }

    qreal blurSaturation() const { return m_blur_saturation; }
    void setBlurSaturation(qreal v) { if (m_blur_saturation != v) { m_blur_saturation = v; emit blurSaturationChanged(); } }

    qreal activeOpacity() const { return m_active_opacity; }
    void setActiveOpacity(qreal v) { if (m_active_opacity != v) { m_active_opacity = v; emit activeOpacityChanged(); } }

    qreal inactiveOpacity() const { return m_inactive_opacity; }
    void setInactiveOpacity(qreal v) { if (m_inactive_opacity != v) { m_inactive_opacity = v; emit inactiveOpacityChanged(); } }

    bool windowBlurEnabled() const { return m_window_blur_enabled; }
    void setWindowBlurEnabled(bool v) { if (m_window_blur_enabled != v) { m_window_blur_enabled = v; emit windowBlurEnabledChanged(); } }

    bool layerBlurEnabled() const { return m_layer_blur_enabled; }
    void setLayerBlurEnabled(bool v) { if (m_layer_blur_enabled != v) { m_layer_blur_enabled = v; emit layerBlurEnabledChanged(); } }

    bool blurXray() const { return m_blur_xray; }
    void setBlurXray(bool v) { if (m_blur_xray != v) { m_blur_xray = v; emit blurXrayChanged(); } }

    qreal shellBlurNoise() const { return m_shell_blur_noise; }
    void setShellBlurNoise(qreal v) { if (m_shell_blur_noise != v) { m_shell_blur_noise = v; emit shellBlurNoiseChanged(); } }

    qreal shellBlurSaturation() const { return m_shell_blur_saturation; }
    void setShellBlurSaturation(qreal v) { if (m_shell_blur_saturation != v) { m_shell_blur_saturation = v; emit shellBlurSaturationChanged(); } }

    int cornerRadius() const { return m_corner_radius; }
    void setCornerRadius(int v) { if (m_corner_radius != v) { m_corner_radius = v; emit cornerRadiusChanged(); } }

    bool clipToGeometry() const { return m_clip_to_geometry; }
    void setClipToGeometry(bool v) { if (m_clip_to_geometry != v) { m_clip_to_geometry = v; emit clipToGeometryChanged(); } }

    bool emptyWorkspaceAboveFirst() const { return m_empty_workspace_above_first; }
    void setEmptyWorkspaceAboveFirst(bool v) { if (m_empty_workspace_above_first != v) { m_empty_workspace_above_first = v; emit emptyWorkspaceAboveFirstChanged(); } }

    QString defaultColumnDisplay() const { return m_default_column_display; }
    void setDefaultColumnDisplay(const QString& v) { if (m_default_column_display != v) { m_default_column_display = v; emit defaultColumnDisplayChanged(); } }

    QString opacityExclusions() const { return m_opacity_exclusions; }
    void setOpacityExclusions(const QString& v) { if (m_opacity_exclusions != v) { m_opacity_exclusions = v; emit opacityExclusionsChanged(); } }

signals:
    void gapsChanged();
    void centerFocusedColumnChanged();
    void alwaysCenterSingleColumnChanged();
    void defaultColumnWidthChanged();
    void focusRingWidthChanged();
    void focusRingActiveChanged();
    void focusRingInactiveChanged();
    void borderEnabledChanged();
    void borderWidthChanged();
    void borderActiveChanged();
    void borderInactiveChanged();
    void shadowEnabledChanged();
    void shadowSoftnessChanged();
    void shadowSpreadChanged();
    void shadowColorChanged();
    void overviewZoomChanged();
    void kbLayoutChanged();
    void kbRepeatDelayChanged();
    void kbRepeatRateChanged();
    void touchpadTapChanged();
    void touchpadNaturalScrollChanged();
    void touchpadAccelSpeedChanged();
    void touchpadClickMethodChanged();
    void mouseAccelProfileChanged();
    void mouseAccelSpeedChanged();
    void warpMouseToFocusChanged();
    void focusFollowsMouseChanged();
    void cursorThemeChanged();
    void cursorSizeChanged();
    void cursorHideWhenTypingChanged();
    void animationsOffChanged();
    void animationsSlowdownChanged();
    void wsDampingChanged();
    void wsStiffnessChanged();
    void winOpenDampingChanged();
    void winOpenStiffnessChanged();
    void winCloseDampingChanged();
    void winCloseStiffnessChanged();
    void resizeDampingChanged();
    void resizeStiffnessChanged();

    // New signals
    void preferNoCsdChanged();
    void blurPassesChanged();
    void blurOffsetChanged();
    void blurNoiseChanged();
    void blurSaturationChanged();
    void activeOpacityChanged();
    void inactiveOpacityChanged();
    void windowBlurEnabledChanged();
    void layerBlurEnabledChanged();
    void blurXrayChanged();
    void shellBlurNoiseChanged();
    void shellBlurSaturationChanged();
    void cornerRadiusChanged();
    void clipToGeometryChanged();
    void emptyWorkspaceAboveFirstChanged();
    void defaultColumnDisplayChanged();
    void opacityExclusionsChanged();

private:
    int m_gaps = 4;
    QString m_center_focused_column = QStringLiteral("never");
    bool m_always_center_single_column = true;
    qreal m_default_column_width = 0.5;
    int m_focus_ring_width = 2;
    QString m_focus_ring_active = QStringLiteral("#c0c0c0");
    QString m_focus_ring_inactive = QStringLiteral("#505050");
    bool m_border_enabled = false;
    int m_border_width = 4;
    QString m_border_active = QStringLiteral("#707070");
    QString m_border_inactive = QStringLiteral("#d0d0d0");
    bool m_shadow_enabled = false;
    int m_shadow_softness = 30;
    int m_shadow_spread = 5;
    QString m_shadow_color = QStringLiteral("#0007");
    qreal m_overview_zoom = 0.75;
    QString m_kb_layout = QStringLiteral("us");
    int m_kb_repeat_delay = 250;
    int m_kb_repeat_rate = 50;
    bool m_touchpad_tap = true;
    bool m_touchpad_natural_scroll = true;
    qreal m_touchpad_accel_speed = 0.0;
    QString m_touchpad_click_method = QStringLiteral("button-areas");
    QString m_mouse_accel_profile = QStringLiteral("flat");
    qreal m_mouse_accel_speed = 0.0;
    bool m_warp_mouse_to_focus = false;
    bool m_focus_follows_mouse = true;
    QString m_cursor_theme = QStringLiteral("default");
    int m_cursor_size = 24;
    bool m_cursor_hide_when_typing = true;
    bool m_animations_off = false;
    qreal m_animations_slowdown = 1.0;
    qreal m_ws_damping = 0.98;
    qreal m_ws_stiffness = 300;
    qreal m_win_open_damping = 0.98;
    qreal m_win_open_stiffness = 300;
    qreal m_win_close_damping = 0.98;
    qreal m_win_close_stiffness = 300;
    qreal m_resize_damping = 0.98;
    qreal m_resize_stiffness = 300;

    // New member variables
    bool m_prefer_no_csd = true;
    int m_blur_passes = 0;
    qreal m_blur_offset = 3.0;
    qreal m_blur_noise = 0.02;
    qreal m_blur_saturation = 1.5;
    qreal m_active_opacity = 1.0;
    qreal m_inactive_opacity = 0.8;
    bool m_window_blur_enabled = false;
    bool m_layer_blur_enabled = false;
    bool m_blur_xray = false;
    qreal m_shell_blur_noise = 0.02;
    qreal m_shell_blur_saturation = 1.5;
    int m_corner_radius = 12;
    bool m_clip_to_geometry = true;
    bool m_empty_workspace_above_first = false;
    QString m_default_column_display = QStringLiteral("normal");
    QString m_opacity_exclusions = QStringLiteral("brave-browser,antigravity-ide,org.quickshell");
};

} // namespace caelestia::services
