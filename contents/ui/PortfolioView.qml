import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.kirigami as Kirigami

Rectangle {
    id: portfolioRoot
    property var rootItem
    property var listModel

    color: Qt.rgba(rootItem.bgColor.r, rootItem.bgColor.g, rootItem.bgColor.b, rootItem.bgOpacity / 100.0)
    radius: 22
    clip: true

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 16
        spacing: 10

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2
                Text {
                    text: "Portfolio"
                    color: rootItem.tickerColor
                    font.pixelSize: 15
                    font.bold: true
                }
                Text {
                    text: (rootItem.lastUpdated && rootItem.nextUpdate) ? "Updated: " + rootItem.lastUpdated + " • Next: " + rootItem.nextUpdate : ""
                    color: rootItem.secondaryTextColor
                    font.pixelSize: 10
                    visible: rootItem.lastUpdated !== "" && !rootItem.hideTimestamps
                }
            }

            ColumnLayout {
                Layout.alignment: Qt.AlignRight
                spacing: 1
                Text {
                    text: rootItem.portfolioCurrencySym + rootItem.formatNumber(rootItem.portfolioTotalValue, false)
                    color: rootItem.priceColor
                    font.pixelSize: 16
                    font.bold: true
                    horizontalAlignment: Text.AlignRight
                }
                Text {
                    text: rootItem.portfolioCurrencySym + rootItem.formatNumber(rootItem.portfolioTotalPnL, true) + " (" + (rootItem.portfolioTotalInvested > 0 ? rootItem.formatNumber((rootItem.portfolioTotalPnL / rootItem.portfolioTotalInvested) * 100, true) : "0.00") + "%)"
                    color: rootItem.portfolioTotalPnL >= 0 ? rootItem.positiveColor : rootItem.negativeColor
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignRight
                }
            }
        }

        Rectangle {
            Layout.fillWidth: true
            height: 1
            color: rootItem.chartBaseColor
            opacity: 0.7
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 6
            Text { text: "Ticker"; color: rootItem.secondaryTextColor; font.pixelSize: 10; Layout.preferredWidth: 60 }
            Text { text: "Shares"; color: rootItem.secondaryTextColor; font.pixelSize: 10; Layout.preferredWidth: 50 }
            Text { text: "Avg Cost"; color: rootItem.secondaryTextColor; font.pixelSize: 10; Layout.preferredWidth: 70 }
            Text { text: "Price"; color: rootItem.secondaryTextColor; font.pixelSize: 10; Layout.preferredWidth: 72 }
            Text { text: "P/L"; color: rootItem.secondaryTextColor; font.pixelSize: 10; Layout.preferredWidth: 80; horizontalAlignment: Text.AlignRight }
        }

        ListView {
            id: portfolioView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            spacing: 0
            model: listModel

            delegate: Item {
                width: portfolioView.width
                height: 38

                RowLayout {
                    anchors.fill: parent
                    spacing: 6

                    Text {
                        text: model.ticker
                        color: rootItem.tickerColor
                        font.pixelSize: 12
                        font.bold: true
                        Layout.preferredWidth: 60
                        elide: Text.ElideRight
                    }
                    Text {
                        text: model.shares
                        color: rootItem.secondaryTextColor
                        font.pixelSize: 11
                        Layout.preferredWidth: 50
                    }
                    Text {
                        text: rootItem.portfolioCurrencySym + rootItem.formatNumber(model.averageCost, false)
                        color: rootItem.secondaryTextColor
                        font.pixelSize: 11
                        Layout.preferredWidth: 70
                    }
                    Text {
                        text: model.currentPriceText
                        color: rootItem.priceColor
                        font.pixelSize: 11
                        Layout.preferredWidth: 72
                    }
                    ColumnLayout {
                        Layout.preferredWidth: 80
                        spacing: 0
                        Text {
                            text: model.unrealizedPnLText
                            color: model.isPos ? rootItem.positiveColor : rootItem.negativeColor
                            font.pixelSize: 11
                            font.bold: true
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                        }
                        Text {
                            text: model.percentReturnText
                            color: model.isPos ? rootItem.positiveColor : rootItem.negativeColor
                            font.pixelSize: 9
                            horizontalAlignment: Text.AlignRight
                            Layout.fillWidth: true
                        }
                    }
                }

                Rectangle {
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.bottom: parent.bottom
                    height: 1
                    color: rootItem.chartBaseColor
                    opacity: 0.5
                    visible: index < portfolioView.count - 1
                }
            }
        }

        Text {
            Layout.fillWidth: true
            text: listModel.count === 0 ? "No portfolio holdings yet." : ""
            visible: listModel.count === 0
            color: rootItem.secondaryTextColor
            font.pixelSize: 12
            horizontalAlignment: Text.AlignHCenter
        }
    }
}
