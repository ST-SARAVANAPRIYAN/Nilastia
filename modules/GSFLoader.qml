import QtQuick
import Quickshell

Item {
    FontLoader {
        source: Quickshell.shellPath("assets/google-sans-flex/GoogleSansFlex-VariableFont_GRAD,ROND,opsz,slnt,wdth,wght.ttf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/NotoSansCJKjp-Regular.otf")
    }
    FontLoader {
        source: Quickshell.shellPath("assets/NotoSansCJKjp-Bold.otf")
    }
}
