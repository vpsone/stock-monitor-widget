import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property alias cfg_positiveColor: posColorButton.text
    property alias cfg_negativeColor: negColorButton.text
    property alias cfg_bgOpacity: opacitySpin.value

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        Kirigami.FormLayout {
            width: parent.availableWidth

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

            SpinBox {
                id: opacitySpin
                Kirigami.FormData.label: "Background Opacity (%):"
                from: 0
                to: 100
            }
        }
    }
}
