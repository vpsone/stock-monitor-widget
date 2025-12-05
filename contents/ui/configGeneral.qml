import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: configPage

    property alias cfg_ticker: tickerField.text
    property alias cfg_refreshInterval: intervalSpin.value
    property alias cfg_isMultiMode: modeSwitch.checked
    property alias cfg_multiTickers: multiListField.text

    // Aliases for new time settings
    property alias cfg_limitHours: limitHoursSwitch.checked
    property alias cfg_startHour: startHourSpin.value
    property alias cfg_startMinute: startMinuteSpin.value
    property alias cfg_endHour: endHourSpin.value
    property alias cfg_endMinute: endMinuteSpin.value

    // 3. CHART RANGE SYNC
    // We define this as a string property to hold the text "1D", "5D", etc.
    property string cfg_chartRange

    // When the config loads (or changes), force the ComboBox to match
    onCfg_chartRangeChanged: {
        var idx = rangeCombo.indexOfValue(cfg_chartRange)
        if (idx >= 0) rangeCombo.currentIndex = idx
    }

    Kirigami.FormLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.margins: 20

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

        // --- CHART RANGE COMBOBOX ---
        ComboBox {
            id: rangeCombo
            Kirigami.FormData.label: "Data Range:"
            model: ["1D", "5D", "1M", "6M", "YTD", "1Y", "5Y", "Max"]

            // 1. Write to config when user selects
            onActivated: configPage.cfg_chartRange = currentText

            // 2. Read from config when window opens
            Component.onCompleted: {
                var idx = indexOfValue(configPage.cfg_chartRange)
                if (idx >= 0) currentIndex = idx
            }
        }

        SpinBox {
            id: intervalSpin
            Kirigami.FormData.label: "Refresh Interval (minutes):"
            from: 1
            to: 360    // Allow up to 6 hours
            stepSize: 1
        }

        // --- NEW TIME SECTION ---
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
    }
}
