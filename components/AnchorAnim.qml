import QtQuick
import Nilastia.Config

AnchorAnimation {
    enum Type {
        StandardSmall = 0,
        Standard,
        StandardLarge,
        StandardExtraLarge,
        EmphasizedSmall,
        Emphasized,
        EmphasizedLarge,
        EmphasizedExtraLarge,
        FastSpatial,
        DefaultSpatial,
        SlowSpatial
    }

    property int type: AnchorAnim.DefaultSpatial

    duration: {
        if (type === AnchorAnim.StandardSmall || type === AnchorAnim.EmphasizedSmall || type === AnchorAnim.FastSpatial)
            return 200;
        if (type === AnchorAnim.Standard || type === AnchorAnim.Emphasized || type === AnchorAnim.DefaultSpatial)
            return 300;
        return 350;
    }
    easing.type: Easing.OutCubic
}
