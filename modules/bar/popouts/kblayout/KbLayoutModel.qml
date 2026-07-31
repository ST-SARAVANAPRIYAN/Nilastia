pragma ComponentBehavior: Bound

import QtQuick
import Quickshell.Io
import Caelestia
import Caelestia.Config

Item {
    id: model

    property alias visibleModel: visibleModel
    property string activeLabel: ""
    property int activeIndex: -1

    function start() {
        refresh();
    }

    function refresh() {
        getKbLayouts.running = true;
    }

    function switchTo(idx) {
        switchProc.command = ["niri", "msg", "action", "switch-layout", String(idx)];
        switchProc.running = true;
    }

    visible: false

    ListModel {
        id: visibleModel
    }

    ListModel {
        id: layoutsModel
    }

    Process {
        id: getKbLayouts

        command: ["niri", "msg", "-j", "keyboard-layouts"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    const j = JSON.parse(text);
                    const names = j.names || [];
                    const currentIdx = j.current_idx ?? -1;

                    layoutsModel.clear();
                    for (let i = 0; i < names.length; i++) {
                        layoutsModel.append({
                            layoutIndex: i,
                            token: names[i],
                            label: names[i]
                        });
                    }

                    model.activeIndex = currentIdx;
                    model.activeLabel = (currentIdx >= 0 && currentIdx < names.length) ? names[currentIdx] : "";

                    visibleModel.clear();
                    for (let i = 0; i < layoutsModel.count; i++) {
                        const it = layoutsModel.get(i);
                        if (it.layoutIndex !== activeIndex) {
                            visibleModel.append({
                                layoutIndex: it.layoutIndex,
                                token: it.token,
                                label: it.label
                              });
                          }
                      }
                  } catch (e) {
                      console.warn("KbLayoutModel: failed to parse keyboard layouts:", e);
                  }
              }
          }
      }

      Process {
          id: switchProc

          onRunningChanged: if (!running)
              refresh()
      }
}
