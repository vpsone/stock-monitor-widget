import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: singleStockRoot
    property var rootItem

    color: Qt.rgba(rootItem.bgColor.r, rootItem.bgColor.g, rootItem.bgColor.b, rootItem.bgOpacity / 100.0)
    radius: 22
    clip: true

    Text {
        anchors.centerIn: parent
        text: "Loading..."
        color: rootItem.secondaryTextColor
        font.pixelSize: 14
        visible: rootItem.isMultiMode && singleStockRoot.visible && (!rootItem.chartDataPoints || rootItem.chartDataPoints.length === 0)
    }

    Item {
        id: singleView
        visible: rootItem.showTwoList || rootItem.singleTicker.trim() !== ""
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.topMargin: 16
        anchors.bottomMargin: 10

        MouseArea {
            anchors.fill: parent
            z: 100 // Ensure it's on top of everything
            cursorShape: Qt.PointingHandCursor
            acceptedButtons: Qt.LeftButton | Qt.MiddleButton
            onClicked: (mouse) => {
                if (mouse.button === Qt.MiddleButton) {
                    if (priceText) priceText.opacity = 0.3;
                    rootItem.refreshData();
                    timerFullFlicker.restart();
                } else {
                    console.log("Opening URL: " + rootItem.singleTicker);
                    Qt.openUrlExternally("https://finance.yahoo.com/quote/" + rootItem.singleTicker);
                }   
            }

            Timer {
                id: timerFullFlicker
                interval: 300
                onTriggered: if (priceText) priceText.opacity = Qt.binding(function() { return rootItem.priceOpacity / 100.0; });
            }
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0
            RowLayout {
                Layout.fillWidth: true
                spacing: 0
                ColumnLayout {
                    spacing: 2
                    Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                    RowLayout {
                        spacing: 5
                        Text {
                            text: rootItem.isPositive ? "▲" : "▼"
                            color: rootItem.isPositive ? rootItem.positiveColor : rootItem.negativeColor
                            font.pixelSize: 12
                            Layout.alignment: Qt.AlignVCenter
                        }
                        Text {
                            text: rootItem.swapNameAndTicker ? rootItem.singleCompanyName : rootItem.singleTicker
                            color: rootItem.tickerColor
                            opacity: rootItem.tickerOpacity / 100.0
                            font.bold: true
                            font.pixelSize: 15
                            font.family: "Arial"
                            Layout.alignment: Qt.AlignVCenter
                            elide: Text.ElideRight
                            Layout.fillWidth: true
                        }
                    }
                    Text {
                        text: rootItem.swapNameAndTicker ? rootItem.singleTicker : rootItem.singleCompanyName
                        color: rootItem.secondaryTextColor
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                    Text {
                        text: (rootItem.lastUpdated && rootItem.nextUpdate) ? "Updated: " + rootItem.lastUpdated + " • Next: " + rootItem.nextUpdate : ""
                        color: rootItem.secondaryTextColor // Slightly brighter
                        font.pixelSize: 9
                        visible: rootItem.lastUpdated !== "" && !rootItem.isMultiMode && !rootItem.hideTimestamps
                    }
                }
                Item { Layout.fillWidth: true }
                ColumnLayout {
                    spacing: 0
                    Layout.alignment: Qt.AlignRight | Qt.AlignTop
                    Text {
                        text: rootItem.percentChange
                        color: rootItem.isPositive ? rootItem.positiveColor : rootItem.negativeColor
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignRight
                        font.bold: true
                    }
                    Text {
                        text: rootItem.priceChange
                        color: rootItem.isPositive ? rootItem.positiveColor : rootItem.negativeColor
                        font.pixelSize: 13
                        Layout.alignment: Qt.AlignRight
                        font.bold: true
                    }
                }
            }
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.topMargin: 10
                Layout.bottomMargin: 5
                Canvas {
                    id: singleCanvas
                    anchors.fill: parent
                    visible: rootItem.chartDataPoints && rootItem.chartDataPoints.length > 0
                    renderStrategy: Canvas.Threaded
                    renderTarget: Canvas.Image
                    onPaint: { drawChart(getContext("2d"), width, height, rootItem.chartDataPoints, rootItem.previousClose, rootItem.isPositive, true); }
                    Connections { target: rootItem; function onChartDataPointsChanged() { singleCanvas.requestPaint(); } }
                }
            }
            Text {
                id: priceText
                Layout.alignment: Qt.AlignHCenter
                text: rootItem.currentPrice
                color: rootItem.priceColor
                opacity: rootItem.priceOpacity / 100.0
                font.pixelSize: 26

                Behavior on opacity { NumberAnimation { duration: 150 } }
            }
        }
    }

    function drawChart(ctx, w, h, data, prevClose, isPos, drawBackground) {
        ctx.clearRect(0, 0, w, h);
        if (!data || data.length < 2) return;
        var minVal = Math.min(...data);
        var maxVal = Math.max(...data);
        var range = maxVal - minVal;
        if (range === 0) range = 1;
        var padding = range * (drawBackground ? 0.1 : 0.05);
        minVal -= padding;
        maxVal += padding;
        range = maxVal - minVal;
        function getY(val) { return h - ((val - minVal) / range * h); }

        if (drawBackground) {
            var prevY = getY(prevClose);
            ctx.beginPath();
            ctx.strokeStyle = rootItem.chartBaseColor;
            ctx.lineWidth = 1;
            ctx.setLineDash([4, 4]);
            ctx.moveTo(0, prevY);
            ctx.lineTo(w, prevY);
            ctx.stroke();
            ctx.setLineDash([]);
        }

        ctx.beginPath();
        var stepX = w / (data.length - 1);
        ctx.moveTo(0, getY(data[0]));
        for (var i = 1; i < data.length; i++) {
            ctx.lineTo(i * stepX, getY(data[i]));
        }

        ctx.lineJoin = "round";
        ctx.lineWidth = 2;
        ctx.strokeStyle = isPos ? rootItem.positiveColor : rootItem.negativeColor;
        ctx.stroke();

        if (drawBackground) {
            ctx.lineTo(w, h);
            ctx.lineTo(0, h);
            ctx.closePath();
            var gradient = ctx.createLinearGradient(0, 0, 0, h);
            var baseColor = isPos ? rootItem.positiveColor : rootItem.negativeColor;
            gradient.addColorStop(0.0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.3));
            gradient.addColorStop(1.0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.0));
            ctx.fillStyle = gradient;
            ctx.fill();
        }
    }
}
