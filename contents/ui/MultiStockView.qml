import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: multiStockRoot
    property var rootItem
    property var listModel

    color: rootItem.bgColor
    radius: 22
    opacity: rootItem.bgOpacity / 100.0

    Text {
        anchors.centerIn: parent
        text: "Loading..."
        color: "#888888"
        font.pixelSize: 14
        visible: rootItem.isMultiMode && listModel.count === 0
    }
    ListView {
        id: multiView
        anchors.fill: parent
        anchors.leftMargin: 16
        anchors.rightMargin: 16
        anchors.bottomMargin: 16
        anchors.topMargin: 0

        clip: true
        model: listModel
        spacing: 0

        delegate: Item {
            width: multiView.width
            height: 60

            MouseArea {
                anchors.fill: parent
                z: 100 // Above the row layout
                cursorShape: Qt.PointingHandCursor
                acceptedButtons: Qt.LeftButton | Qt.MiddleButton | Qt.RightButton
                onClicked: (mouse) => {
                    if (mouse.button === Qt.MiddleButton) {
                        parent.opacity = 0.4;
                        rootItem.refreshData();
                        timerListFlicker.restart();
                    } else if (mouse.button === Qt.LeftButton) {
                        console.log("Opening URL: " + model.ticker);
                        Qt.openUrlExternally("https://finance.yahoo.com/quote/" + model.ticker);
                    } else if (mouse.button === Qt.RightButton) {
                        rootItem.manualPanelTickerOverride = model.ticker;
                        rootItem.singleTicker = model.ticker; // Also update singleTicker to keep singleView in sync
                        rootItem.refreshData();
                    }
                }
                Timer {
                    id: timerListFlicker
                    interval: 300
                    onTriggered: parent.opacity = 1.0;
                }
            }

            RowLayout {
                anchors.fill: parent
                spacing: 10
                ColumnLayout {
                    Layout.preferredWidth: parent.width * 0.35
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 2
                    RowLayout {
                        spacing: 4
                        Text {
                            text: model.isPos ? "▲" : "▼"
                            color: model.isPos ? rootItem.positiveColor : rootItem.negativeColor
                            font.pixelSize: 10
                        }
                        Text {
                            text: rootItem.swapNameAndTicker ? model.name : model.ticker
                            color: "white"
                            font.pixelSize: 14
                        }
                    }
                    Text {
                        text: rootItem.swapNameAndTicker ? model.ticker : model.name
                        color: "#888888"
                        font.pixelSize: 10
                        elide: Text.ElideRight
                        Layout.fillWidth: true
                    }
                }

                ColumnLayout {
                    Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                    spacing: 2
                    Text {
                        text: model.price
                        color: "white"
                        font.pixelSize: 14
                        Layout.alignment: Qt.AlignRight
                    }
                    Rectangle {
                        radius: 4
                        // Background: translucent tint of the color for theme independence
                        color: model.isPos
                            ? Qt.rgba(rootItem.positiveColor.r, rootItem.positiveColor.g, rootItem.positiveColor.b, 0.15)
                            : Qt.rgba(rootItem.negativeColor.r, rootItem.negativeColor.g, rootItem.negativeColor.b, 0.15)
                        border.color: model.isPos ? rootItem.positiveColor : rootItem.negativeColor
                        border.width: 1
                        Layout.preferredWidth: pctTextL.implicitWidth + (Kirigami.Units.smallSpacing * 2)
                        Layout.preferredHeight: pctTextL.implicitHeight + (Kirigami.Units.smallSpacing / 2)
                        Layout.alignment: Qt.AlignRight

                        Text {
                            id: pctTextL
                            anchors.centerIn: parent
                            text: model.change + " (" + model.pct + ")"
                            color: model.isPos ? rootItem.positiveColor : rootItem.negativeColor
                            font.pixelSize: 11
                            font.weight: Font.Black
                        }
                    }
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: "#333333"
                visible: index < multiView.count - 1
            }
        }
    }
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 8
        text: (rootItem.lastUpdated && rootItem.nextUpdate) ? "Updated: " + rootItem.lastUpdated + " • Next: " + rootItem.nextUpdate : ""
        color: "#777777"
        font.pixelSize: 10
        visible: rootItem.lastUpdated !== "" && rootItem.isMultiMode && !rootItem.hideTimestamps
    }
}
