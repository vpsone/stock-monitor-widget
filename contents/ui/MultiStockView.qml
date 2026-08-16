import QtQuick
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Rectangle {
    id: multiStockRoot

    property var rootItem
    property var listModel

    color: rootItem.bgColor
    radius: rootItem.isPlasmaTheme ? 0 : 22
    clip: true

    Text {
        anchors.centerIn: parent
        text: "Loading..."
        color: rootItem.secondaryTextColor
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
            id: rowRoot
            width: multiView.width
            // Computed here (not stored as a model role) because ListModel silently converts
            // an array-of-objects role into a nested QQmlListModel on append(), which breaks
            // plain JS array access like .length/[i] in a nested Repeater. Calling the helper
            // directly keeps it a real JS array, and it's still reactive since the expression
            // reads rootItem.portfolioData and model.currentRaw directly.
            property var rowLots: (rootItem.showPortfolioMode && model.currentRaw > 0) ? rootItem.getPortfolioLots(model.ticker, rootItem.portfolioData, model.currentRaw) : []
            // Base row + one extra line per portfolio lot for this ticker (each lot's own
            // purchase price compared against the live price).
            height: 60 + (rowRoot.rowLots.length > 0 ? (rowRoot.rowLots.length * 13 + 4) : 0)
            // Captured here (not read inside the nested Repeater below) because that Repeater's
            // own delegate shadows the ListView's "model" context property with its own.
            property string rowCurrencySym: model.currencySym

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

            // Outer ColumnLayout so the per-lot lines stack *below* the name/price row instead
            // of inside it — keeping them inside the row's own ColumnLayout would grow that
            // column's content height and, since it's independently vertically-centered, pull
            // the price up out of line with the ticker name whenever a ticker had lots.
            ColumnLayout {
                anchors.fill: parent
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 60
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
                                color: rootItem.tickerColor
                                opacity: rootItem.tickerOpacity / 100.0
                                font.pixelSize: 14
                            }
                        }
                        Text {
                            text: rootItem.swapNameAndTicker ? model.ticker : model.name
                            color: rootItem.secondaryTextColor
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
                            color: rootItem.priceColor
                            opacity: rootItem.priceOpacity / 100.0
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

                // One line per lot bought for this ticker (own purchase price vs. live price),
                // below the core row so it never affects that row's own alignment.
                Repeater {
                    model: rowRoot.rowLots
                    delegate: Text {
                        Layout.fillWidth: true
                        horizontalAlignment: Text.AlignRight
                        text: modelData.shares + " @ " + rowRoot.rowCurrencySym + modelData.avgCost.toFixed(2)
                              + " → " + rootItem.formatNumber(modelData.plValue, true)
                              + " (" + rootItem.formatNumber(modelData.plPercent, true) + "%)"
                        color: modelData.plIsPos ? rootItem.positiveColor : rootItem.negativeColor
                        font.pixelSize: 9
                    }
                }
            }
            Rectangle {
                anchors.bottom: parent.bottom
                anchors.left: parent.left
                anchors.right: parent.right
                height: 1
                color: rootItem.chartBaseColor
                visible: index < multiView.count - 1
            }
        }
    }
    Text {
        anchors.bottom: parent.bottom
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.bottomMargin: 8
        text: (rootItem.lastUpdated && rootItem.nextUpdate) ? "Updated: " + rootItem.lastUpdated + " • Next: " + rootItem.nextUpdate : ""
        color: rootItem.secondaryTextColor
        font.pixelSize: 10
        visible: rootItem.lastUpdated !== "" && rootItem.isMultiMode && !rootItem.hideTimestamps
    }
}
