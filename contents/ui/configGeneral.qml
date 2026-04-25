import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property alias cfg_ticker: tickerField.text
    property alias cfg_refreshInterval: intervalSpin.value
    property alias cfg_isMultiMode: modeSwitch.checked
    property alias cfg_showTwoList: showTwoListSwitch.checked
    property alias cfg_multiTickers: multiListField.text
    property alias cfg_sortAlphabetically: sortSwitch.checked
    property alias cfg_swapNameAndTicker: swapNameSwitch.checked
    
    property alias cfg_limitHours: limitHoursSwitch.checked
    property alias cfg_skipWeekendRefresh: skipWeekendRefreshSwitch.checked
    property alias cfg_hideTimestamps: hideTimestampsSwitch.checked
    property alias cfg_formatPrices: formatPricesSwitch.checked
    property alias cfg_hideDecimals: hideDecimalsSwitch.checked
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
            CheckBox {
                visible: modeSwitch.checked
                id: showTwoListSwitch
                Kirigami.FormData.label: "Two List:"
                text: "single-stock on left side and multi-stock on right side"
            }
            TextField {
                id: tickerField
                visible: !modeSwitch.checked
                Kirigami.FormData.label: "Single Ticker:"
                placeholderText: "e.g., AAPL"
            }

            ScrollView {
                visible: modeSwitch.checked
                Kirigami.FormData.label: "Ticker List:"
                Layout.fillWidth: true
                Layout.minimumHeight: 60
                Layout.maximumHeight: 500
                
                TextArea {
                    id: multiListField
                    placeholderText: "AAPL, TSLA"
                    wrapMode: TextEdit.Wrap
                }
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
                text: "Only refresh data during market hours"
            }

            CheckBox {
                id: skipWeekendRefreshSwitch
                Kirigami.FormData.label: "Weekend Refresh:"
                text: "Do not refresh data on weekends (Sat,Sun)"
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
            
            CheckBox {
                id: formatPricesSwitch
                Kirigami.FormData.label: "Value Formatting:"
                text: "Format stock price with commas (e.g. 1,000.00)"
            }

            CheckBox {
                id: hideDecimalsSwitch
                text: "Remove decimals from stock price"
            }
            
        }
    }
}
