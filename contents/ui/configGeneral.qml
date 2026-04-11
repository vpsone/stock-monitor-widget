import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property alias cfg_ticker: tickerField.text
    property alias cfg_refreshInterval: intervalSpin.value
    property alias cfg_isMultiMode: modeSwitch.checked
    property alias cfg_multiTickers: multiListField.text
    property alias cfg_sortAlphabetically: sortSwitch.checked
    property alias cfg_swapNameAndTicker: swapNameSwitch.checked
    
    property alias cfg_limitHours: limitHoursSwitch.checked
    property alias cfg_hideTimestamps: hideTimestampsSwitch.checked
    property alias cfg_startHour: startHourSpin.value
    property alias cfg_startMinute: startMinuteSpin.value
    property alias cfg_endHour: endHourSpin.value
    property alias cfg_endMinute: endMinuteSpin.value

    property string cfg_chartRange

    onCfg_chartRangeChanged: {
        var idx = rangeCombo.indexOfValue(cfg_chartRange)
        if (idx >= 0) rangeCombo.currentIndex = idx
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        Kirigami.FormLayout {
            width: parent.availableWidth

            CheckBox {
                id: modeSwitch
                Kirigami.FormData.label: "Display Mode:"
                text: "Show Multi-Stock List"
            }

            TextField {
                id: tickerField
                visible: !modeSwitch.checked
                Kirigami.FormData.label: "Single Ticker:"
                placeholderText: "e.g., AAPL"
            }

            TextArea {
                id: multiListField
                visible: modeSwitch.checked
                Kirigami.FormData.label: "Ticker List:"
                placeholderText: "AAPL, TSLA"
                Layout.fillWidth: true
                Layout.minimumHeight: 60
            }

            CheckBox {
                id: sortSwitch
                visible: modeSwitch.checked
                Kirigami.FormData.label: "Sorting:"
                text: "Sort stocks alphabetically"
            }

            CheckBox {
                id: swapNameSwitch
                Kirigami.FormData.label: "Swap Names:"
                text: "Swap company name and ticker symbol"
            }

            ComboBox {
                id: rangeCombo
                Kirigami.FormData.label: "Data Range:"
                model: ["1D", "5D", "1M", "6M", "YTD", "1Y", "5Y", "Max"]
                onActivated: page.cfg_chartRange = currentText
                Component.onCompleted: {
                    var idx = indexOfValue(page.cfg_chartRange)
                    if (idx >= 0) currentIndex = idx
                }
            }

            SpinBox {
                id: intervalSpin
                Kirigami.FormData.label: "Refresh Interval (minutes):"
                from: 1
                to: 360
            }

            CheckBox {
                id: limitHoursSwitch
                Kirigami.FormData.label: "Active Hours:"
                text: "Only update during market hours"
            }

            RowLayout {
                visible: limitHoursSwitch.checked
                Kirigami.FormData.label: "Market Open:"
                SpinBox { id: startHourSpin; from: 0; to: 23; }
                Label { text: ":" }
                SpinBox { id: startMinuteSpin; from: 0; to: 59; }
            }

            RowLayout {
                visible: limitHoursSwitch.checked
                Kirigami.FormData.label: "Market Close:"
                SpinBox { id: endHourSpin; from: 0; to: 23; }
                Label { text: ":" }
                SpinBox { id: endMinuteSpin; from: 0; to: 59; }
            }

            CheckBox {
                id: hideTimestampsSwitch
                Kirigami.FormData.label: "Update Timestamps:"
                text: "Hide update timestamps"
            }
        }
    }
}
