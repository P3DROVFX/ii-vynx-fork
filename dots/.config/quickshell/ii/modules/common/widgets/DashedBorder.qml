import QtQuick
import qs.modules.common
import qs.modules.common.functions

Canvas {
    id: root
    property color color: "#ffffff"
    property int dashLength: 6
    property int gapLength: 4
    property int borderWidth: 1
    property real radius: 0

    onDashLengthChanged: requestPaint()
    onGapLengthChanged: requestPaint()
    onRadiusChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()
    onPaint: {
        var ctx = getContext("2d");
        ctx.clearRect(0, 0, width, height);
        ctx.save();
        ctx.strokeStyle = root.color;
        ctx.lineWidth = root.borderWidth;
        if (root.gapLength > 0) {
            ctx.setLineDash([root.dashLength, root.gapLength]); // Set dash pattern
        }
        if (root.radius > 0) {
            var r = root.radius;
            var w = width;
            var h = height;
            var b = root.borderWidth / 2;
            ctx.beginPath();
            ctx.moveTo(b + r, b);
            ctx.lineTo(w - b - r, b);
            ctx.arcTo(w - b, b, w - b, b + r, r);
            ctx.lineTo(w - b, h - b - r);
            ctx.arcTo(w - b, h - b, w - b - r, h - b, r);
            ctx.lineTo(b + r, h - b);
            ctx.arcTo(b, h - b, b, h - b - r, r);
            ctx.lineTo(b, b + r);
            ctx.arcTo(b, b, b + r, b, r);
            ctx.closePath();
            ctx.stroke();
        } else {
            ctx.strokeRect(root.borderWidth / 2, root.borderWidth / 2, width - root.borderWidth, height - root.borderWidth); // Draw it
        }
        ctx.restore();
    }
}
