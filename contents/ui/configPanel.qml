import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property alias cfg_hideChangePercentage: hidePercentSwitch.checked

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        Kirigami.FormLayout {
            width: parent.availableWidth

            CheckBox {
                id: hidePercentSwitch
                Kirigami.FormData.label: "Stock Change Percentage:"
                text: "Hide stock change percentage"
            }
        }
    }
}
