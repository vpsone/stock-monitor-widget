import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property alias cfg_isLightTheme: lightThemeSwitch.checked
    property alias cfg_positiveColor: posColorButton.text
    property alias cfg_negativeColor: negColorButton.text
    property alias cfg_bgOpacity: bgOpacitySlider.value
    property alias cfg_tickerColor: tickerColorButton.text
    property alias cfg_tickerOpacity: tickerOpacitySlider.value
    property alias cfg_priceColor: priceColorButton.text
    property alias cfg_priceOpacity: priceOpacitySlider.value

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        Kirigami.FormLayout {
            width: parent.availableWidth

            Switch {
                id: lightThemeSwitch
                Kirigami.FormData.label: "Theme:"
                text: "Use Light Theme"
            }

            TextField {
                id: posColorButton
                Kirigami.FormData.label: "Positive Color (Hex):"
                placeholderText: "#00ff00"
            }

            TextField {
                id: negColorButton
                Kirigami.FormData.label: "Negative Color (Hex):"
                placeholderText: "#ff3b30"
            }

            RowLayout {
                Kirigami.FormData.label: "Background Opacity:"
                Slider {
                    id: bgOpacitySlider
                    from: 0
                    to: 100
                    stepSize: 1
                    Layout.fillWidth: true
                }
                Label {
                    text: bgOpacitySlider.value + "%"
                }
            }

            Item {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Ticker Symbol Text"
            }

            TextField {
                id: tickerColorButton
                Kirigami.FormData.label: "Color (Hex):"
                placeholderText: "#FFFFFF"
            }

            RowLayout {
                Kirigami.FormData.label: "Opacity:"
                Slider {
                    id: tickerOpacitySlider
                    from: 0
                    to: 100
                    stepSize: 1
                    Layout.fillWidth: true
                }
                Label {
                    text: tickerOpacitySlider.value + "%"
                }
            }

            Item {
                Kirigami.FormData.isSection: true
                Kirigami.FormData.label: "Stock Price Text"
            }

            TextField {
                id: priceColorButton
                Kirigami.FormData.label: "Color (Hex):"
                placeholderText: "#FFFFFF"
            }

            RowLayout {
                Kirigami.FormData.label: "Opacity:"
                Slider {
                    id: priceOpacitySlider
                    from: 0
                    to: 100
                    stepSize: 1
                    Layout.fillWidth: true
                }
                Label {
                    text: priceOpacitySlider.value + "%"
                }
            }
        }
    }
}
