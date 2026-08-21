#include "compositorconfig.hpp"

#include <qdir.h>
#include <qfile.h>
#include <qtextstream.h>
#include <qregularexpression.h>
#include <qpair.h>
#include <qfileinfo.h>
#include <qprocess.h>
#include <qtimer.h>
#include <qcoreapplication.h>
#include <qdebug.h>

namespace nilastia::services {

namespace {

QString configDir() {
    return QDir::homePath() + QStringLiteral("/.config/niri/config.d");
}

QString getFileContent(const QString& filename) {
    QString path = configDir() + QStringLiteral("/") + filename;
    if (filename == QStringLiteral("config.kdl")) {
        path = QDir::homePath() + QStringLiteral("/.config/niri/config.kdl");
    }
    QFile file(path);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString();
    }
    QTextStream in(&file);
    return in.readAll();
}

void writeFileContent(const QString& filename, const QString& content) {
    QString path = configDir() + QStringLiteral("/") + filename;
    if (filename == QStringLiteral("config.kdl")) {
        path = QDir::homePath() + QStringLiteral("/.config/niri/config.kdl");
    }
    QDir().mkpath(QFileInfo(path).absolutePath());
    QFile file(path);
    if (file.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&file);
        out << content;
        out.flush();
        file.close();
        if (filename != QStringLiteral("config.kdl")) {
            static QTimer* reloadTimer = nullptr;
            if (!reloadTimer) {
                reloadTimer = new QTimer(QCoreApplication::instance());
                reloadTimer->setSingleShot(true);
                reloadTimer->setInterval(350); // 350ms debounce window
                QObject::connect(reloadTimer, &QTimer::timeout, []() {
                    qDebug() << "[CompositorConfig] Debounced reload triggered for Niri";
                    QProcess::startDetached(QStringLiteral("niri"), {QStringLiteral("msg"), QStringLiteral("action"), QStringLiteral("load-config-file")});
                });
            }
            reloadTimer->start();
        }
    }
}

// Balanced bracket block helper
QString findBalancedBlock(const QString& content, int startIndex) {
    int braceCount = 0;
    bool foundOpen = false;
    int endIndex = -1;
    for (int i = startIndex; i < content.length(); ++i) {
        if (content[i] == QLatin1Char('{')) {
            braceCount++;
            foundOpen = true;
        } else if (content[i] == QLatin1Char('}')) {
            braceCount--;
            if (foundOpen && braceCount == 0) {
                endIndex = i;
                break;
            }
        }
    }
    if (endIndex != -1) {
        return content.mid(startIndex, endIndex - startIndex + 1);
    }
    return QString();
}

QString extractBalancedBlock(const QString& content, const QString& blockName) {
    QRegularExpression re(blockName + QStringLiteral("\\s*\\{"));
    auto match = re.match(content);
    if (match.hasMatch()) {
        int startIdx = match.capturedStart(0);
        QString block = findBalancedBlock(content, startIdx);
        int openBraceIdx = block.indexOf(QLatin1Char('{'));
        if (openBraceIdx != -1 && block.endsWith(QLatin1Char('}'))) {
            return block.mid(openBraceIdx + 1, block.length() - openBraceIdx - 2);
        }
    }
    return QString();
}

bool getBoolFlag(const QString& content, const QString& flagName, const QString& blockName = QString()) {
    QString searchIn = content;
    if (!blockName.isEmpty()) {
        searchIn = extractBalancedBlock(content, blockName);
        if (searchIn.isEmpty()) return false;
    }
    
    QStringList lines = searchIn.split(QLatin1Char('\n'));
    for (const auto& line : lines) {
        QString stripped = line.trimmed();
        if (stripped.startsWith(QStringLiteral("//")) || stripped.startsWith(QStringLiteral("#"))) continue;
        QRegularExpression re(QStringLiteral("\\b") + flagName + QStringLiteral("\\b"));
        if (re.match(stripped).hasMatch()) {
            return true;
        }
    }
    return false;
}

bool getBoolValue(const QString& content, const QString& flagName, bool defaultValue) {
    QRegularExpression re(flagName + QStringLiteral("\\s+(true|false)"));
    auto match = re.match(content);
    if (match.hasMatch()) {
        return match.captured(1) == QStringLiteral("true");
    }
    QRegularExpression flagRe(QStringLiteral("\\b") + flagName + QStringLiteral("\\b"));
    if (flagRe.match(content).hasMatch()) {
        QStringList lines = content.split(QLatin1Char('\n'));
        for (const auto& line : lines) {
            QString stripped = line.trimmed();
            if (stripped.startsWith(QStringLiteral("//")) || stripped.startsWith(QStringLiteral("#"))) continue;
            if (flagRe.match(stripped).hasMatch()) {
                return true;
            }
        }
    }
    return defaultValue;
}

QString setBoolFlag(const QString& content, const QString& flagName, bool enabled, const QString& blockName = QString()) {
    if (!blockName.isEmpty()) {
        QRegularExpression re(blockName + QStringLiteral("\\s*\\{"));
        auto match = re.match(content);
        if (!match.hasMatch()) {
            if (enabled) {
                return content + QStringLiteral("\n") + blockName + QStringLiteral(" {\n    ") + flagName + QStringLiteral("\n}\n");
            }
            return content;
        }
        int startIdx = match.capturedStart(0);
        QString block = findBalancedBlock(content, startIdx);
        QString newBlock = setBoolFlag(block, flagName, enabled, QString());
        QString result = content;
        return result.replace(block, newBlock);
    }

    QStringList lines = content.split(QLatin1Char('\n'));
    bool found = false;
    QRegularExpression re(QStringLiteral("\\b") + flagName + QStringLiteral("\\b"));
    for (int i = 0; i < lines.size(); ++i) {
        QString lineStripped = lines[i].trimmed();
        if (re.match(lineStripped).hasMatch()) {
            found = true;
            bool isCommented = lineStripped.startsWith(QStringLiteral("//")) || lineStripped.startsWith(QStringLiteral("#"));
            if (enabled && isCommented) {
                QRegularExpression commentRe(QStringLiteral("^(?:\\s*//\\s*)+"));
                lines[i] = lines[i].replace(commentRe, QStringLiteral("    "));
            } else if (!enabled && !isCommented) {
                int indent = lines[i].length() - lines[i].trimmed().length();
                lines[i] = lines[i].left(indent) + QStringLiteral("// ") + lineStripped;
            }
            break;
        }
    }

    if (!found && enabled) {
        for (int i = lines.size() - 1; i >= 0; --i) {
            if (lines[i].trimmed() == QStringLiteral("}")) {
                lines.insert(i, QStringLiteral("    ") + flagName);
                found = true;
                break;
            }
        }
        if (!found) {
            lines.append(flagName);
        }
    }

    return lines.join(QLatin1Char('\n'));
}

double getDoubleValue(const QString& content, const QRegularExpression& pattern, double defaultValue, const QString& blockName = QString()) {
    QString searchIn = content;
    if (!blockName.isEmpty()) {
        searchIn = extractBalancedBlock(content, blockName);
        if (searchIn.isEmpty()) return defaultValue;
    }
    QStringList lines = searchIn.split(QLatin1Char('\n'));
    for (const auto& line : lines) {
        QString stripped = line.trimmed();
        if (stripped.startsWith(QStringLiteral("//")) || stripped.startsWith(QStringLiteral("#"))) continue;
        auto match = pattern.match(stripped);
        if (match.hasMatch()) {
            return match.captured(1).toDouble();
        }
    }
    return defaultValue;
}

int getIntValue(const QString& content, const QRegularExpression& pattern, int defaultValue, const QString& blockName = QString()) {
    QString searchIn = content;
    if (!blockName.isEmpty()) {
        searchIn = extractBalancedBlock(content, blockName);
        if (searchIn.isEmpty()) return defaultValue;
    }
    QStringList lines = searchIn.split(QLatin1Char('\n'));
    for (const auto& line : lines) {
        QString stripped = line.trimmed();
        if (stripped.startsWith(QStringLiteral("//")) || stripped.startsWith(QStringLiteral("#"))) continue;
        auto match = pattern.match(stripped);
        if (match.hasMatch()) {
            return match.captured(1).toInt();
        }
    }
    return defaultValue;
}

QString getStringValue(const QString& content, const QRegularExpression& pattern, const QString& defaultValue, const QString& blockName = QString()) {
    QString searchIn = content;
    if (!blockName.isEmpty()) {
        searchIn = extractBalancedBlock(content, blockName);
        if (searchIn.isEmpty()) return defaultValue;
    }
    QStringList lines = searchIn.split(QLatin1Char('\n'));
    for (const auto& line : lines) {
        QString stripped = line.trimmed();
        if (stripped.startsWith(QStringLiteral("//")) || stripped.startsWith(QStringLiteral("#"))) continue;
        auto match = pattern.match(stripped);
        if (match.hasMatch()) {
            return match.captured(1);
        }
    }
    return defaultValue;
}

QString setValue(const QString& content, const QRegularExpression& pattern, const QString& replacementFormat, const QVariant& value, const QString& blockName = QString()) {
    if (!blockName.isEmpty()) {
        QRegularExpression re(blockName + QStringLiteral("\\s*\\{"));
        auto match = re.match(content);
        if (!match.hasMatch()) {
            return content + QStringLiteral("\n") + blockName + QStringLiteral(" {\n    ") + replacementFormat.arg(value.toString()) + QStringLiteral("\n}\n");
        }
        int startIdx = match.capturedStart(0);
        QString block = findBalancedBlock(content, startIdx);
        QString newBlock = setValue(block, pattern, replacementFormat, value, QString());
        QString result = content;
        return result.replace(block, newBlock);
    }

    QStringList lines = content.split(QLatin1Char('\n'));
    bool found = false;
    for (int i = 0; i < lines.size(); ++i) {
        QString lineStripped = lines[i].trimmed();
        if (pattern.match(lineStripped).hasMatch()) {
            found = true;
            QString newLine = lineStripped;
            newLine.replace(pattern, replacementFormat.arg(value.toString()));
            if (newLine.startsWith(QStringLiteral("//")) || newLine.startsWith(QStringLiteral("#"))) {
                QRegularExpression commentRe(QStringLiteral("^(?:\\s*//\\s*)+"));
                newLine = newLine.replace(commentRe, QString());
            }
            int indent = lines[i].length() - lines[i].trimmed().length();
            lines[i] = QString(indent, QLatin1Char(' ')) + newLine;
            break;
        }
    }

    if (!found) {
        for (int i = lines.size() - 1; i >= 0; --i) {
            if (lines[i].trimmed() == QStringLiteral("}")) {
                lines.insert(i, QStringLiteral("    ") + replacementFormat.arg(value.toString()));
                break;
            }
        }
    }

    return lines.join(QLatin1Char('\n'));
}

QPair<qreal, qreal> getSpringParams(const QString& content, const QString& category) {
    QRegularExpression pattern(QStringLiteral("spring\\s+damping-ratio=([0-9.]+)\\s+stiffness=([0-9.]+)"));
    QString block = extractBalancedBlock(content, category);
    if (!block.isEmpty()) {
        auto match = pattern.match(block);
        if (match.hasMatch()) {
            return { match.captured(1).toDouble(), match.captured(2).toDouble() };
        }
    }
    return { 0.98, 300.0 };
}

QString setSpringParams(const QString& content, const QString& category, qreal damping, qreal stiffness) {
    QRegularExpression pattern(category + QStringLiteral("\\s*\\{[^}]*\\}"));
    QString replacement = category + QStringLiteral(" { spring damping-ratio=") + QString::number(damping, 'f', 2) + QStringLiteral(" stiffness=") + QString::number(stiffness, 'f', 0) + QStringLiteral(" epsilon=0.0001 }");
    
    auto match = pattern.match(content);
    if (match.hasMatch()) {
        QString result = content;
        return result.replace(match.captured(0), replacement);
    } else {
        QRegularExpression animMatch(QStringLiteral("(animations\\s*\\{)"));
        auto matchAnim = animMatch.match(content);
        if (matchAnim.hasMatch()) {
            int idx = content.indexOf(matchAnim.captured(1)) + matchAnim.captured(1).length();
            QString result = content;
            result.insert(idx, QStringLiteral("\n    ") + replacement + QStringLiteral("\n"));
            return result;
        }
    }
    return content;
}

// Tag-based Block helpers
QString getBlockByTag(const QString& content, const QString& tag) {
    int startIdx = content.indexOf(QStringLiteral("// ") + tag + QStringLiteral(":start"));
    if (startIdx == -1) return QString();
    int endIdx = content.indexOf(QStringLiteral("// ") + tag + QStringLiteral(":end"), startIdx);
    if (endIdx == -1) return QString();
    return content.mid(startIdx, endIdx - startIdx);
}

QString setBlockByTag(const QString& content, const QString& tag, const QString& newBlockContent) {
    int startIdx = content.indexOf(QStringLiteral("// ") + tag + QStringLiteral(":start"));
    if (startIdx == -1) {
        return content + QStringLiteral("\n// ") + tag + QStringLiteral(":start\n") + newBlockContent + QStringLiteral("\n// ") + tag + QStringLiteral(":end\n");
    }
    int endIdx = content.indexOf(QStringLiteral("// ") + tag + QStringLiteral(":end"), startIdx);
    if (endIdx == -1) return content;
    
    int replaceStart = startIdx + QStringLiteral("// ").length() + tag.length() + QStringLiteral(":start\n").length();
    QString result = content;
    return result.replace(replaceStart, endIdx - replaceStart, newBlockContent + QStringLiteral("\n"));
}

QString buildGeometryBlock(int cornerRadius, bool clipToGeometry) {
    return QStringLiteral("window-rule {\n") +
           QStringLiteral("    geometry-corner-radius ") + QString::number(cornerRadius) + QStringLiteral("\n") +
           QStringLiteral("    clip-to-geometry ") + (clipToGeometry ? QStringLiteral("true") : QStringLiteral("false")) + QStringLiteral("\n") +
           QStringLiteral("}");
}

QString buildUnifiedRulesBlock(bool blurEnabled, bool xray, qreal noise, qreal saturation, qreal activeOpacity, qreal inactiveOpacity, const QString& exclusionsStr) {
    QString block;
    QString excludeRule;
    if (!exclusionsStr.isEmpty()) {
        QStringList list = exclusionsStr.split(QLatin1Char(','));
        QStringList escapedList;
        for (auto& item : list) {
            QString trimmed = item.trimmed();
            if (!trimmed.isEmpty()) {
                QString escaped = trimmed;
                escaped.replace(QStringLiteral("."), QStringLiteral("\\."));
                escapedList.append(escaped);
            }
        }
        if (!escapedList.isEmpty()) {
            excludeRule = QStringLiteral("    exclude app-id=r#\"^(") + escapedList.join(QLatin1Char('|')) + QStringLiteral(")$\"#\n");
        }
    }

    QString effectBlock = QStringLiteral("    background-effect {\n") +
                          QStringLiteral("        blur ") + (blurEnabled ? QStringLiteral("true") : QStringLiteral("false")) + QStringLiteral("\n") +
                          QStringLiteral("        xray ") + (xray ? QStringLiteral("true") : QStringLiteral("false")) + QStringLiteral("\n") +
                          QStringLiteral("        noise ") + QString::number(noise, 'f', 3) + QStringLiteral("\n") +
                          QStringLiteral("        saturation ") + QString::number(saturation, 'f', 2) + QStringLiteral("\n") +
                          QStringLiteral("    }\n");

    block += QStringLiteral("window-rule {\n") +
             QStringLiteral("    match is-active=true\n") +
             excludeRule +
             QStringLiteral("    opacity ") + QString::number(activeOpacity, 'f', 2) + QStringLiteral("\n") +
             QStringLiteral("    draw-border-with-background false\n") +
             effectBlock +
             QStringLiteral("}\n\n");

    block += QStringLiteral("window-rule {\n") +
             QStringLiteral("    match is-active=false\n") +
             excludeRule +
             QStringLiteral("    opacity ") + QString::number(inactiveOpacity, 'f', 2) + QStringLiteral("\n") +
             QStringLiteral("    draw-border-with-background false\n") +
             effectBlock +
             QStringLiteral("}");
    return block;
}

QString getLayerRuleBlock(const QString& content) {
    return getBlockByTag(content, QStringLiteral("ii-managed-blur-layer-rules"));
}

bool getLayerRuleBlur(const QString& content) {
    QString block = getLayerRuleBlock(content);
    if (!block.isEmpty()) {
        QRegularExpression blurRe(QStringLiteral("blur\\s+(true|false)"));
        auto blurMatch = blurRe.match(block);
        if (blurMatch.hasMatch()) {
            return blurMatch.captured(1) == QStringLiteral("true");
        }
    }
    return false;
}

QString setLayerRuleBlur(const QString& content, bool enabled, qreal noise, qreal saturation) {
    if (!enabled) {
        return setBlockByTag(content, QStringLiteral("ii-managed-blur-layer-rules"), QString());
    }
    QString newBlock = QStringLiteral("layer-rule {\n") +
                       QStringLiteral("    match namespace=\"^(launcher|waybar|walker|fuzzel|wofi|tofi|rofi|yofi|ags|swaync|mako)$\"\n") +
                       QStringLiteral("    opacity 0.85\n") +
                       QStringLiteral("    background-effect {\n") +
                       QStringLiteral("        blur true\n") +
                       QStringLiteral("        xray false\n") +
                       QStringLiteral("        noise %1\n").arg(noise) +
                       QStringLiteral("        saturation %1\n").arg(saturation) +
                       QStringLiteral("    }\n") +
                       QStringLiteral("}\n\n") +
                       QStringLiteral("layer-rule {\n") +
                       QStringLiteral("    match namespace=\"nilastia-drawers\"\n") +
                       QStringLiteral("    background-effect {\n") +
                       QStringLiteral("        xray false\n") +
                       QStringLiteral("        noise %1\n").arg(noise) +
                       QStringLiteral("        saturation %1\n").arg(saturation) +
                       QStringLiteral("    }\n") +
                       QStringLiteral("}");
    return setBlockByTag(content, QStringLiteral("ii-managed-blur-layer-rules"), newBlock);
}

} // namespace

Compositor::Compositor(QObject* parent)
    : QObject(parent) {
    load();
}

void Compositor::load() {
    QString configKdlContent = getFileContent(QStringLiteral("config.kdl"));
    QString inputContent = getFileContent(QStringLiteral("10-input-and-cursor.kdl"));
    QString layoutContent = getFileContent(QStringLiteral("20-layout-and-overview.kdl"));
    QString windowRulesContent = getFileContent(QStringLiteral("30-window-rules.kdl"));
    QString animContent = getFileContent(QStringLiteral("60-animations.kdl"));
    QString layerRulesContent = getFileContent(QStringLiteral("80-layer-rules.kdl"));

    // Layout
    setGaps(getIntValue(layoutContent, QRegularExpression(QStringLiteral("gaps\\s+(\\d+)")), 4));
    setCenterFocusedColumn(getStringValue(layoutContent, QRegularExpression(QStringLiteral("center-focused-column\\s+\"([^\"]+)\"")), QStringLiteral("never")));
    setAlwaysCenterSingleColumn(getBoolFlag(layoutContent, QStringLiteral("always-center-single-column")));
    setDefaultColumnWidth(getDoubleValue(layoutContent, QRegularExpression(QStringLiteral("proportion\\s+([0-9.]+)")), 0.5, QStringLiteral("default-column-width")));
    
    setFocusRingWidth(getIntValue(layoutContent, QRegularExpression(QStringLiteral("width\\s+(\\d+)")), 2, QStringLiteral("focus-ring")));
    setFocusRingActive(getStringValue(layoutContent, QRegularExpression(QStringLiteral("active-color\\s+\"([^\"]+)\"")), QStringLiteral("#c0c0c0"), QStringLiteral("focus-ring")));
    setFocusRingInactive(getStringValue(layoutContent, QRegularExpression(QStringLiteral("inactive-color\\s+\"([^\"]+)\"")), QStringLiteral("#505050"), QStringLiteral("focus-ring")));

    setBorderEnabled(!getBoolFlag(layoutContent, QStringLiteral("off"), QStringLiteral("border")));
    setBorderWidth(getIntValue(layoutContent, QRegularExpression(QStringLiteral("width\\s+(\\d+)")), 4, QStringLiteral("border")));
    setBorderActive(getStringValue(layoutContent, QRegularExpression(QStringLiteral("active-color\\s+\"([^\"]+)\"")), QStringLiteral("#707070"), QStringLiteral("border")));
    setBorderInactive(getStringValue(layoutContent, QRegularExpression(QStringLiteral("inactive-color\\s+\"([^\"]+)\"")), QStringLiteral("#d0d0d0"), QStringLiteral("border")));

    setShadowEnabled(!getBoolFlag(layoutContent, QStringLiteral("off"), QStringLiteral("shadow")));
    setShadowSoftness(getIntValue(layoutContent, QRegularExpression(QStringLiteral("softness\\s+(\\d+)")), 30, QStringLiteral("shadow")));
    setShadowSpread(getIntValue(layoutContent, QRegularExpression(QStringLiteral("spread\\s+(\\d+)")), 5, QStringLiteral("shadow")));
    setShadowColor(getStringValue(layoutContent, QRegularExpression(QStringLiteral("color\\s+\"([^\"]+)\"")), QStringLiteral("#0007"), QStringLiteral("shadow")));

    setOverviewZoom(getDoubleValue(layoutContent, QRegularExpression(QStringLiteral("zoom\\s+([0-9.]+)")), 0.75, QStringLiteral("overview")));

    // Input
    setKbLayout(getStringValue(inputContent, QRegularExpression(QStringLiteral("layout\\s+\"([^\"]+)\"")), QStringLiteral("us"), QStringLiteral("xkb")));
    setKbRepeatDelay(getIntValue(inputContent, QRegularExpression(QStringLiteral("repeat-delay\\s+(\\d+)")), 250, QStringLiteral("keyboard")));
    setKbRepeatRate(getIntValue(inputContent, QRegularExpression(QStringLiteral("repeat-rate\\s+(\\d+)")), 50, QStringLiteral("keyboard")));

    setTouchpadTap(getBoolFlag(inputContent, QStringLiteral("tap"), QStringLiteral("touchpad")));
    setTouchpadNaturalScroll(getBoolFlag(inputContent, QStringLiteral("natural-scroll"), QStringLiteral("touchpad")));
    setTouchpadAccelSpeed(getDoubleValue(inputContent, QRegularExpression(QStringLiteral("accel-speed\\s+([0-9.-]+)")), 0.0, QStringLiteral("touchpad")));
    setTouchpadClickMethod(getStringValue(inputContent, QRegularExpression(QStringLiteral("click-method\\s+\"([^\"]+)\"")), QStringLiteral("button-areas"), QStringLiteral("touchpad")));

    setMouseAccelProfile(getStringValue(inputContent, QRegularExpression(QStringLiteral("accel-profile\\s+\"([^\"]+)\"")), QStringLiteral("flat"), QStringLiteral("mouse")));
    setMouseAccelSpeed(getDoubleValue(inputContent, QRegularExpression(QStringLiteral("accel-speed\\s+([0-9.-]+)")), 0.0, QStringLiteral("mouse")));

    setWarpMouseToFocus(getBoolFlag(inputContent, QStringLiteral("warp-mouse-to-focus")));
    setFocusFollowsMouse(getBoolFlag(inputContent, QStringLiteral("focus-follows-mouse")));

    setCursorTheme(getStringValue(inputContent, QRegularExpression(QStringLiteral("xcursor-theme\\s+\"([^\"]+)\"")), QStringLiteral("default"), QStringLiteral("cursor")));
    setCursorSize(getIntValue(inputContent, QRegularExpression(QStringLiteral("xcursor-size\\s+(\\d+)")), 24, QStringLiteral("cursor")));
    setCursorHideWhenTyping(getBoolFlag(inputContent, QStringLiteral("hide-when-typing"), QStringLiteral("cursor")));

    // Animations
    setAnimationsOff(getBoolFlag(animContent, QStringLiteral("off")));
    setAnimationsSlowdown(getDoubleValue(animContent, QRegularExpression(QStringLiteral("slowdown\\s+([0-9.]+)")), 1.0));

    auto wsSpring = getSpringParams(animContent, QStringLiteral("workspace-switch"));
    setWsDamping(wsSpring.first);
    setWsStiffness(wsSpring.second);

    auto openSpring = getSpringParams(animContent, QStringLiteral("window-open"));
    setWinOpenDamping(openSpring.first);
    setWinOpenStiffness(openSpring.second);

    auto closeSpring = getSpringParams(animContent, QStringLiteral("window-close"));
    setWinCloseDamping(closeSpring.first);
    setWinCloseStiffness(closeSpring.second);

    auto resizeSpring = getSpringParams(animContent, QStringLiteral("window-resize"));
    setResizeDamping(resizeSpring.first);
    setResizeStiffness(resizeSpring.second);

    // CSD & Blur & Transparency Load
    setPreferNoCsd(getBoolFlag(configKdlContent, QStringLiteral("prefer-no-csd")));
    setBlurPasses(getIntValue(configKdlContent, QRegularExpression(QStringLiteral("passes\\s+(\\d+)")), 0, QStringLiteral("blur")));
    setBlurOffset(getDoubleValue(configKdlContent, QRegularExpression(QStringLiteral("offset\\s+([0-9.-]+)")), 3.0, QStringLiteral("blur")));
    setBlurNoise(getDoubleValue(configKdlContent, QRegularExpression(QStringLiteral("noise\\s+([0-9.-]+)")), 0.02, QStringLiteral("blur")));
    setBlurSaturation(getDoubleValue(configKdlContent, QRegularExpression(QStringLiteral("saturation\\s+([0-9.-]+)")), 1.5, QStringLiteral("blur")));

    setLayerBlurEnabled(getLayerRuleBlur(layerRulesContent));
    QString layerBlock = getLayerRuleBlock(layerRulesContent);
    if (!layerBlock.isEmpty()) {
        setShellBlurNoise(getDoubleValue(layerBlock, QRegularExpression(QStringLiteral("noise\\s+([0-9.-]+)")), 0.02));
        setShellBlurSaturation(getDoubleValue(layerBlock, QRegularExpression(QStringLiteral("saturation\\s+([0-9.-]+)")), 1.5));
    } else {
        setShellBlurNoise(0.02);
        setShellBlurSaturation(1.5);
    }

    // Corner Radius, Clip, Opacities, Blur rule Load via new tagged blocks
    QString geomBlock = getBlockByTag(windowRulesContent, QStringLiteral("ii-managed-geometry-rules"));
    if (!geomBlock.isEmpty()) {
        setCornerRadius(getIntValue(geomBlock, QRegularExpression(QStringLiteral("geometry-corner-radius\\s+(\\d+)")), 12));
        setClipToGeometry(getBoolValue(geomBlock, QStringLiteral("clip-to-geometry"), true));
    } else {
        setCornerRadius(12);
        setClipToGeometry(true);
    }

    QString opacityBlock = getBlockByTag(windowRulesContent, QStringLiteral("ii-managed-opacity-rules"));
    if (!opacityBlock.isEmpty()) {
        QRegularExpression activeRe(QStringLiteral("match\\s+is-active\\s*=\\s*true(?:\\r?\\n|.)*?opacity\\s+([0-9.-]+)"));
        auto activeMatch = activeRe.match(opacityBlock);
        if (activeMatch.hasMatch()) {
            setActiveOpacity(activeMatch.captured(1).toDouble());
        } else {
            setActiveOpacity(1.0);
        }
        
        QRegularExpression inactiveRe(QStringLiteral("match\\s+is-active\\s*=\\s*false(?:\\r?\\n|.)*?opacity\\s+([0-9.-]+)"));
        auto inactiveMatch = inactiveRe.match(opacityBlock);
        if (inactiveMatch.hasMatch()) {
            setInactiveOpacity(inactiveMatch.captured(1).toDouble());
        } else {
            setInactiveOpacity(0.8);
        }

        // Parse window blur settings from unified block
        QRegularExpression blurRe(QStringLiteral("blur\\s+(true|false)"));
        auto blurMatch = blurRe.match(opacityBlock);
        if (blurMatch.hasMatch()) {
            setWindowBlurEnabled(blurMatch.captured(1) == QStringLiteral("true"));
        } else {
            setWindowBlurEnabled(false);
        }

        QRegularExpression xrayRe(QStringLiteral("xray\\s+(true|false)"));
        auto xrayMatch = xrayRe.match(opacityBlock);
        if (xrayMatch.hasMatch()) {
            setBlurXray(xrayMatch.captured(1) == QStringLiteral("true"));
        } else {
            setBlurXray(false);
        }

        QRegularExpression excludeRe(QStringLiteral("exclude\\s+app-id\\s*=\\s*r#\"\\^\\(([^)]+)\\)\\$\"#"));
        auto excludeMatch = excludeRe.match(opacityBlock);
        if (excludeMatch.hasMatch()) {
            QString rawExcludes = excludeMatch.captured(1);
            rawExcludes.replace(QStringLiteral("\\."), QStringLiteral("."));
            rawExcludes.replace(QStringLiteral("|"), QStringLiteral(","));
            setOpacityExclusions(rawExcludes);
        } else {
            setOpacityExclusions(QStringLiteral("brave-browser,antigravity-ide,org.quickshell"));
        }
    } else {
        setActiveOpacity(1.0);
        setInactiveOpacity(0.8);
        setWindowBlurEnabled(false);
        setBlurXray(false);
        setOpacityExclusions(QStringLiteral("brave-browser,antigravity-ide,org.quickshell"));
    }

    // Load extra layout fields
    setEmptyWorkspaceAboveFirst(getBoolFlag(layoutContent, QStringLiteral("empty-workspace-above-first")));
    setDefaultColumnDisplay(getStringValue(layoutContent, QRegularExpression(QStringLiteral("default-column-display\\s+\"([^\"]+)\"")), QStringLiteral("normal")));

    qDebug() << "[CompositorConfig] load() m_opacity_exclusions:" << m_opacity_exclusions;
}

void Compositor::saveValue(const QString& key, const QVariant& value) {
    qDebug() << "[CompositorConfig] saveValue called for key:" << key << "value:" << value;
    QString configKdlContent = getFileContent(QStringLiteral("config.kdl"));
    QString inputContent = getFileContent(QStringLiteral("10-input-and-cursor.kdl"));
    QString layoutContent = getFileContent(QStringLiteral("20-layout-and-overview.kdl"));
    QString windowRulesContent = getFileContent(QStringLiteral("30-window-rules.kdl"));
    QString animContent = getFileContent(QStringLiteral("60-animations.kdl"));
    QString layerRulesContent = getFileContent(QStringLiteral("80-layer-rules.kdl"));

    bool changedConfig = false;
    bool changedInput = false;
    bool changedLayout = false;
    bool changedWindowRules = false;
    bool changedAnim = false;
    bool changedLayerRules = false;

    // Layout
    if (key == QStringLiteral("gaps")) {
        setGaps(value.toInt());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("gaps\\s+\\d+")), QStringLiteral("gaps %1"), value, QString());
        changedLayout = true;
    } else if (key == QStringLiteral("center_focused_column")) {
        setCenterFocusedColumn(value.toString());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("center-focused-column\\s+\"[^\"]+\"")), QStringLiteral("center-focused-column \"%1\""), value, QString());
        changedLayout = true;
    } else if (key == QStringLiteral("always_center_single_column")) {
        setAlwaysCenterSingleColumn(value.toBool());
        layoutContent = setBoolFlag(layoutContent, QStringLiteral("always-center-single-column"), value.toBool(), QString());
        changedLayout = true;
    } else if (key == QStringLiteral("default_column_width")) {
        setDefaultColumnWidth(value.toDouble());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("proportion\\s+[0-9.]+")), QStringLiteral("proportion %1"), value, QStringLiteral("default-column-width"));
        changedLayout = true;
    } else if (key == QStringLiteral("focus_ring_width")) {
        setFocusRingWidth(value.toInt());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("width\\s+\\d+")), QStringLiteral("width %1"), value, QStringLiteral("focus-ring"));
        changedLayout = true;
    } else if (key == QStringLiteral("focus_ring_active")) {
        setFocusRingActive(value.toString());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("active-color\\s+\"[^\"]+\"")), QStringLiteral("active-color \"%1\""), value, QStringLiteral("focus-ring"));
        changedLayout = true;
    } else if (key == QStringLiteral("focus_ring_inactive")) {
        setFocusRingInactive(value.toString());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("inactive-color\\s+\"[^\"]+\"")), QStringLiteral("inactive-color \"%1\""), value, QStringLiteral("focus-ring"));
        changedLayout = true;
    } else if (key == QStringLiteral("border_enabled")) {
        setBorderEnabled(value.toBool());
        layoutContent = setBoolFlag(layoutContent, QStringLiteral("off"), !value.toBool(), QStringLiteral("border"));
        changedLayout = true;
    } else if (key == QStringLiteral("border_width")) {
        setBorderWidth(value.toInt());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("width\\s+\\d+")), QStringLiteral("width %1"), value, QStringLiteral("border"));
        changedLayout = true;
    } else if (key == QStringLiteral("border_active")) {
        setBorderActive(value.toString());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("active-color\\s+\"[^\"]+\"")), QStringLiteral("active-color \"%1\""), value, QStringLiteral("border"));
        changedLayout = true;
    } else if (key == QStringLiteral("border_inactive")) {
        setBorderInactive(value.toString());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("inactive-color\\s+\"[^\"]+\"")), QStringLiteral("inactive-color \"%1\""), value, QStringLiteral("border"));
        changedLayout = true;
    } else if (key == QStringLiteral("shadow_enabled")) {
        setShadowEnabled(value.toBool());
        layoutContent = setBoolFlag(layoutContent, QStringLiteral("off"), !value.toBool(), QStringLiteral("shadow"));
        changedLayout = true;
    } else if (key == QStringLiteral("shadow_softness")) {
        setShadowSoftness(value.toInt());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("softness\\s+\\d+")), QStringLiteral("softness %1"), value, QStringLiteral("shadow"));
        changedLayout = true;
    } else if (key == QStringLiteral("shadow_spread")) {
        setShadowSpread(value.toInt());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("spread\\s+\\d+")), QStringLiteral("spread %1"), value, QStringLiteral("shadow"));
        changedLayout = true;
    } else if (key == QStringLiteral("shadow_color")) {
        setShadowColor(value.toString());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("color\\s+\"[^\"]+\"")), QStringLiteral("color \"%1\""), value, QStringLiteral("shadow"));
        changedLayout = true;
    } else if (key == QStringLiteral("overview_zoom")) {
        setOverviewZoom(value.toDouble());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("zoom\\s+[0-9.]+")), QStringLiteral("zoom %1"), value, QStringLiteral("overview"));
        changedLayout = true;
    } else if (key == QStringLiteral("empty_workspace_above_first")) {
        setEmptyWorkspaceAboveFirst(value.toBool());
        layoutContent = setBoolFlag(layoutContent, QStringLiteral("empty-workspace-above-first"), value.toBool(), QString());
        changedLayout = true;
    } else if (key == QStringLiteral("default_column_display")) {
        setDefaultColumnDisplay(value.toString());
        layoutContent = setValue(layoutContent, QRegularExpression(QStringLiteral("default-column-display\\s+\"[^\"]+\"")), QStringLiteral("default-column-display \"%1\""), value, QString());
        changedLayout = true;
    }

    // Input settings
    else if (key == QStringLiteral("kb_layout")) {
        setKbLayout(value.toString());
        inputContent = setValue(inputContent, QRegularExpression(QStringLiteral("layout\\s+\"[^\"]+\"")), QStringLiteral("layout \"%1\""), value, QStringLiteral("xkb"));
        changedInput = true;
    } else if (key == QStringLiteral("kb_repeat_delay")) {
        setKbRepeatDelay(value.toInt());
        inputContent = setValue(inputContent, QRegularExpression(QStringLiteral("repeat-delay\\s+\\d+")), QStringLiteral("repeat-delay %1"), value, QStringLiteral("keyboard"));
        changedInput = true;
    } else if (key == QStringLiteral("kb_repeat_rate")) {
        setKbRepeatRate(value.toInt());
        inputContent = setValue(inputContent, QRegularExpression(QStringLiteral("repeat-rate\\s+\\d+")), QStringLiteral("repeat-rate %1"), value, QStringLiteral("keyboard"));
        changedInput = true;
    } else if (key == QStringLiteral("touchpad_tap")) {
        setTouchpadTap(value.toBool());
        inputContent = setBoolFlag(inputContent, QStringLiteral("tap"), value.toBool(), QStringLiteral("touchpad"));
        changedInput = true;
    } else if (key == QStringLiteral("touchpad_natural_scroll")) {
        setTouchpadNaturalScroll(value.toBool());
        inputContent = setBoolFlag(inputContent, QStringLiteral("natural-scroll"), value.toBool(), QStringLiteral("touchpad"));
        changedInput = true;
    } else if (key == QStringLiteral("touchpad_accel_speed")) {
        setTouchpadAccelSpeed(value.toDouble());
        inputContent = setValue(inputContent, QRegularExpression(QStringLiteral("accel-speed\\s+[0-9.-]+")), QStringLiteral("accel-speed %1"), value, QStringLiteral("touchpad"));
        changedInput = true;
    } else if (key == QStringLiteral("touchpad_click_method")) {
        setTouchpadClickMethod(value.toString());
        inputContent = setValue(inputContent, QRegularExpression(QStringLiteral("click-method\\s+\"[^\"]+\"")), QStringLiteral("click-method \"%1\""), value, QStringLiteral("touchpad"));
        changedInput = true;
    } else if (key == QStringLiteral("mouse_accel_profile")) {
        setMouseAccelProfile(value.toString());
        inputContent = setValue(inputContent, QRegularExpression(QStringLiteral("accel-profile\\s+\"[^\"]+\"")), QStringLiteral("accel-profile \"%1\""), value, QStringLiteral("mouse"));
        changedInput = true;
    } else if (key == QStringLiteral("mouse_accel_speed")) {
        setMouseAccelSpeed(value.toDouble());
        inputContent = setValue(inputContent, QRegularExpression(QStringLiteral("accel-speed\\s+[0-9.-]+")), QStringLiteral("accel-speed %1"), value, QStringLiteral("mouse"));
        changedInput = true;
    } else if (key == QStringLiteral("warp_mouse_to_focus")) {
        setWarpMouseToFocus(value.toBool());
        inputContent = setBoolFlag(inputContent, QStringLiteral("warp-mouse-to-focus"), value.toBool(), QString());
        changedInput = true;
    } else if (key == QStringLiteral("focus_follows_mouse")) {
        setFocusFollowsMouse(value.toBool());
        inputContent = setBoolFlag(inputContent, QStringLiteral("focus-follows-mouse"), value.toBool(), QString());
        changedInput = true;
    } else if (key == QStringLiteral("cursor_theme")) {
        setCursorTheme(value.toString());
        inputContent = setValue(inputContent, QRegularExpression(QStringLiteral("xcursor-theme\\s+\"[^\"]+\"")), QStringLiteral("xcursor-theme \"%1\""), value, QStringLiteral("cursor"));
        changedInput = true;
    } else if (key == QStringLiteral("cursor_size")) {
        setCursorSize(value.toInt());
        inputContent = setValue(inputContent, QRegularExpression(QStringLiteral("xcursor-size\\s+\\d+")), QStringLiteral("xcursor-size %1"), value, QStringLiteral("cursor"));
        changedInput = true;
    } else if (key == QStringLiteral("cursor_hide_when_typing")) {
        setCursorHideWhenTyping(value.toBool());
        inputContent = setBoolFlag(inputContent, QStringLiteral("hide-when-typing"), value.toBool(), QStringLiteral("cursor"));
        changedInput = true;
    }

    // Animation settings
    else if (key == QStringLiteral("animations_off")) {
        setAnimationsOff(value.toBool());
        animContent = setBoolFlag(animContent, QStringLiteral("off"), value.toBool(), QString());
        changedAnim = true;
    } else if (key == QStringLiteral("animations_slowdown")) {
        setAnimationsSlowdown(value.toDouble());
        animContent = setValue(animContent, QRegularExpression(QStringLiteral("slowdown\\s+[0-9.]+")), QStringLiteral("slowdown %1"), value, QString());
        changedAnim = true;
    } else if (key == QStringLiteral("ws_damping") || key == QStringLiteral("ws_stiffness")) {
        if (key == QStringLiteral("ws_damping")) setWsDamping(value.toDouble());
        else setWsStiffness(value.toDouble());
        animContent = setSpringParams(animContent, QStringLiteral("workspace-switch"), m_ws_damping, m_ws_stiffness);
        changedAnim = true;
    } else if (key == QStringLiteral("win_open_damping") || key == QStringLiteral("win_open_stiffness")) {
        if (key == QStringLiteral("win_open_damping")) setWinOpenDamping(value.toDouble());
        else setWinOpenStiffness(value.toDouble());
        animContent = setSpringParams(animContent, QStringLiteral("window-open"), m_win_open_damping, m_win_open_stiffness);
        changedAnim = true;
    } else if (key == QStringLiteral("win_close_damping") || key == QStringLiteral("win_close_stiffness")) {
        if (key == QStringLiteral("win_close_damping")) setWinCloseDamping(value.toDouble());
        else setWinCloseStiffness(value.toDouble());
        animContent = setSpringParams(animContent, QStringLiteral("window-close"), m_win_close_damping, m_win_close_stiffness);
        changedAnim = true;
    } else if (key == QStringLiteral("resize_damping") || key == QStringLiteral("resize_stiffness")) {
        if (key == QStringLiteral("resize_damping")) setResizeDamping(value.toDouble());
        else setResizeStiffness(value.toDouble());
        animContent = setSpringParams(animContent, QStringLiteral("window-resize"), m_resize_damping, m_resize_stiffness);
        changedAnim = true;
    }

    // New settings
    else if (key == QStringLiteral("prefer_no_csd")) {
        setPreferNoCsd(value.toBool());
        configKdlContent = setBoolFlag(configKdlContent, QStringLiteral("prefer-no-csd"), value.toBool(), QString());
        changedConfig = true;
    } else if (key == QStringLiteral("blur_passes")) {
        setBlurPasses(value.toInt());
        configKdlContent = setValue(configKdlContent, QRegularExpression(QStringLiteral("passes\\s+\\d+")), QStringLiteral("passes %1"), value, QStringLiteral("blur"));
        changedConfig = true;
    } else if (key == QStringLiteral("blur_offset")) {
        setBlurOffset(value.toDouble());
        configKdlContent = setValue(configKdlContent, QRegularExpression(QStringLiteral("offset\\s+[0-9.-]+")), QStringLiteral("offset %1"), value, QStringLiteral("blur"));
        changedConfig = true;
    } else if (key == QStringLiteral("blur_noise")) {
        setBlurNoise(value.toDouble());
        configKdlContent = setValue(configKdlContent, QRegularExpression(QStringLiteral("noise\\s+[0-9.-]+")), QStringLiteral("noise %1"), value, QStringLiteral("blur"));
        changedConfig = true;
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-blur-rules"), QString());
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-opacity-rules"), buildUnifiedRulesBlock(m_window_blur_enabled, m_blur_xray, m_blur_noise, m_blur_saturation, m_active_opacity, m_inactive_opacity, m_opacity_exclusions));
        changedWindowRules = true;
    } else if (key == QStringLiteral("blur_saturation")) {
        setBlurSaturation(value.toDouble());
        configKdlContent = setValue(configKdlContent, QRegularExpression(QStringLiteral("saturation\\s+[0-9.-]+")), QStringLiteral("saturation %1"), value, QStringLiteral("blur"));
        changedConfig = true;
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-blur-rules"), QString());
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-opacity-rules"), buildUnifiedRulesBlock(m_window_blur_enabled, m_blur_xray, m_blur_noise, m_blur_saturation, m_active_opacity, m_inactive_opacity, m_opacity_exclusions));
        changedWindowRules = true;
    } else if (key == QStringLiteral("layer_blur_enabled")) {
        setLayerBlurEnabled(value.toBool());
        layerRulesContent = setLayerRuleBlur(layerRulesContent, value.toBool(), m_shell_blur_noise, m_shell_blur_saturation);
        changedLayerRules = true;
    } else if (key == QStringLiteral("shell_blur_noise") || key == QStringLiteral("shell_blur_saturation")) {
        if (key == QStringLiteral("shell_blur_noise")) setShellBlurNoise(value.toDouble());
        else setShellBlurSaturation(value.toDouble());
        layerRulesContent = setLayerRuleBlur(layerRulesContent, m_layer_blur_enabled, m_shell_blur_noise, m_shell_blur_saturation);
        changedLayerRules = true;
    }

    // Tagged block saves
    else if (key == QStringLiteral("corner_radius") || key == QStringLiteral("clip_to_geometry")) {
        if (key == QStringLiteral("corner_radius")) setCornerRadius(value.toInt());
        else setClipToGeometry(value.toBool());
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-geometry-rules"), buildGeometryBlock(m_corner_radius, m_clip_to_geometry));
        changedWindowRules = true;
    } else if (key == QStringLiteral("window_blur_enabled") || key == QStringLiteral("blur_xray")) {
        if (key == QStringLiteral("window_blur_enabled")) setWindowBlurEnabled(value.toBool());
        else setBlurXray(value.toBool());
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-blur-rules"), QString());
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-opacity-rules"), buildUnifiedRulesBlock(m_window_blur_enabled, m_blur_xray, m_blur_noise, m_blur_saturation, m_active_opacity, m_inactive_opacity, m_opacity_exclusions));
        changedWindowRules = true;
    } else if (key == QStringLiteral("active_opacity") || key == QStringLiteral("inactive_opacity")) {
        if (key == QStringLiteral("active_opacity")) setActiveOpacity(value.toDouble());
        else setInactiveOpacity(value.toDouble());
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-blur-rules"), QString());
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-opacity-rules"), buildUnifiedRulesBlock(m_window_blur_enabled, m_blur_xray, m_blur_noise, m_blur_saturation, m_active_opacity, m_inactive_opacity, m_opacity_exclusions));
        changedWindowRules = true;
    } else if (key == QStringLiteral("opacity_exclusions")) {
        setOpacityExclusions(value.toString());
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-blur-rules"), QString());
        windowRulesContent = setBlockByTag(windowRulesContent, QStringLiteral("ii-managed-opacity-rules"), buildUnifiedRulesBlock(m_window_blur_enabled, m_blur_xray, m_blur_noise, m_blur_saturation, m_active_opacity, m_inactive_opacity, m_opacity_exclusions));
        changedWindowRules = true;
    }

    if (changedConfig) {
        writeFileContent(QStringLiteral("config.kdl"), configKdlContent);
    }
    if (changedInput) {
        writeFileContent(QStringLiteral("10-input-and-cursor.kdl"), inputContent);
    }
    if (changedLayout) {
        writeFileContent(QStringLiteral("20-layout-and-overview.kdl"), layoutContent);
    }
    if (changedWindowRules) {
        writeFileContent(QStringLiteral("30-window-rules.kdl"), windowRulesContent);
    }
    if (changedAnim) {
        writeFileContent(QStringLiteral("60-animations.kdl"), animContent);
    }
    if (changedLayerRules) {
        writeFileContent(QStringLiteral("80-layer-rules.kdl"), layerRulesContent);
    }
}

} // namespace nilastia::services
