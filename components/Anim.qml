import QtQuick
import Nilastia.Config

NumberAnimation {
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
        SlowSpatial,
        FastEffects,
        DefaultEffects,
        SlowEffects
    }

    property int type: Anim.DefaultSpatial

    duration: {
        if (type === Anim.StandardSmall || type === Anim.EmphasizedSmall || type === Anim.FastSpatial || type === Anim.FastEffects)
            return 200;
        if (type === Anim.Standard || type === Anim.Emphasized || type === Anim.DefaultSpatial || type === Anim.DefaultEffects)
            return 300;
        return 350;
    }
    easing.type: Easing.OutCubic
}
