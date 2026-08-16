pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import Nilastia.Config
import qs.components
import qs.services

ColumnLayout {
    id: layout
    spacing: Tokens.spacing.extraSmall

    StyledRect {
        Layout.alignment: Qt.AlignHCenter
        implicitWidth: Tokens.sizes.bar.innerWidth - Tokens.padding.extraSmall * 2
        implicitHeight: implicitWidth
        radius: implicitWidth / 2
        
        color: Colours.tPalette.m3surfaceContainerHigh
        border.width: 1
        border.color: Colours.palette.m3outlineVariant

        Canvas {
            id: analogCanvas
            anchors.fill: parent
            anchors.margins: 4

            // Redraw every second
            Connections {
                target: Time
                function onSecondChanged() {
                    analogCanvas.requestPaint();
                }
            }

            onPaint: {
                let ctx = getContext("2d");
                ctx.reset();

                let cx = width / 2;
                let cy = height / 2;
                let r = Math.min(width, height) / 2;

                // Draw face background circle
                ctx.beginPath();
                ctx.arc(cx, cy, r - 1, 0, 2 * Math.PI);
                ctx.fillStyle = Colours.palette.m3surface;
                ctx.fill();

                // Draw tick marks at 12, 3, 6, 9
                ctx.lineWidth = 2;
                ctx.strokeStyle = Colours.palette.m3outlineVariant;
                for (let i = 0; i < 4; i++) {
                    let angle = i * Math.PI / 2;
                    ctx.beginPath();
                    ctx.moveTo(cx + (r - 4) * Math.cos(angle), cy + (r - 4) * Math.sin(angle));
                    ctx.lineTo(cx + (r - 1) * Math.cos(angle), cy + (r - 1) * Math.sin(angle));
                    ctx.stroke();
                }

                // Get current time angles
                let date = new Date();
                let hrs = date.getHours();
                let mins = date.getMinutes();
                let secs = date.getSeconds();

                // Hour Hand (Primary Accent)
                let hrAngle = (hrs % 12) * Math.PI / 6 + mins * Math.PI / 360 - Math.PI / 2;
                ctx.lineWidth = 3;
                ctx.strokeStyle = Colours.palette.m3primary;
                ctx.beginPath();
                ctx.moveTo(cx, cy);
                ctx.lineTo(cx + (r * 0.5) * Math.cos(hrAngle), cy + (r * 0.5) * Math.sin(hrAngle));
                ctx.stroke();

                // Minute Hand (Secondary Accent)
                let minAngle = mins * Math.PI / 30 + secs * Math.PI / 1800 - Math.PI / 2;
                ctx.lineWidth = 2;
                ctx.strokeStyle = Colours.palette.m3secondary;
                ctx.beginPath();
                ctx.moveTo(cx, cy);
                ctx.lineTo(cx + (r * 0.75) * Math.cos(minAngle), cy + (r * 0.75) * Math.sin(minAngle));
                ctx.stroke();

                // Second Hand (Tertiary Accent)
                let secAngle = secs * Math.PI / 30 - Math.PI / 2;
                ctx.lineWidth = 1;
                ctx.strokeStyle = Colours.palette.m3tertiary;
                ctx.beginPath();
                ctx.moveTo(cx, cy);
                ctx.lineTo(cx + (r * 0.8) * Math.cos(secAngle), cy + (r * 0.8) * Math.sin(secAngle));
                ctx.stroke();

                // Center Pin
                ctx.beginPath();
                ctx.arc(cx, cy, 3, 0, 2 * Math.PI);
                ctx.fillStyle = Colours.palette.m3outline;
                ctx.fill();
            }
        }
    }

    // Small numeric date label below analog dial
    Loader {
        Layout.alignment: Qt.AlignHCenter
        active: Config.bar.clock.showDate
        visible: active
        sourceComponent: StyledText {
            text: Time.format("d")
            font: Tokens.font.body.builders.small.scale(0.85).bold().build()
            color: Colours.palette.m3onSurfaceVariant
        }
    }
}
