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

    // Aliases for new settings
    property alias cfg_limitHours: limitHoursSwitch.checked
    property alias cfg_startHour: startHourSpin.value
    property alias cfg_startMinute: startMinuteSpin.value
    property alias cfg_endHour: endHourSpin.value
    property alias cfg_endMinute: endMinuteSpin.value
    property alias cfg_positiveColor: posColorButton.text
    property alias cfg_negativeColor: negColorButton.text
    property alias cfg_hideChangePercentage: hidePercentSwitch.checked
    property alias cfg_hideTimestamps: hideTimestampsSwitch.checked

    // Portfolio settings
    property alias cfg_showPortfolioMode: portfolioModeSwitch.checked
    property string cfg_portfolioData

    property string cfg_chartRange

    onCfg_chartRangeChanged: {
        var idx = rangeCombo.indexOfValue(cfg_chartRange)
        if (idx >= 0) rangeCombo.currentIndex = idx
    }

    function searchSymbols(query) {
        if (query.length < 2) {
            searchHelpText.text = "Type at least 2 characters...";
            return;
        }
        var xhr = new XMLHttpRequest();
        // Use query2 for search
        var url = "https://query2.finance.yahoo.com/v1/finance/search?q=" + encodeURIComponent(query);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                try {
                    var res = JSON.parse(xhr.responseText);
                    var results = res.quotes || [];
                    if (results.length === 0) {
                        searchHelpText.text = "No symbols found.";
                        return;
                    }
                    var displayStr = "Suggestions (Symbol - Name):\n";
                    for (var i = 0; i < Math.min(results.length, 5); i++) {
                        displayStr += "• " + results[i].symbol + " - " + (results[i].shortname || results[i].longname || "") + "\n";
                    }
                    searchHelpText.text = displayStr;
                } catch (e) { searchHelpText.text = "Error searching."; }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    function formatPortfolioList(portfolio) {
        if (!portfolio || portfolio.length === 0) {
            return "No holdings added yet.";
        }
        var displayStr = "Current Holdings:\n";
        for (var i = 0; i < portfolio.length; i++) {
            displayStr += "• " + portfolio[i].ticker + ": " + portfolio[i].shares + " shares @ " + portfolio[i].averageCost.toFixed(2) + "\n";
        }
        return displayStr;
    }

    function safeParsePortfolio(data) {
        if (!data) return [];
        try {
            return JSON.parse(data);
        } catch (e) {
            console.error("Failed to parse portfolio data:", e);
            return [];
        }
    }

    function escapeCsvField(val) {
        var str = String(val);
        if (str.indexOf(",") >= 0 || str.indexOf("\"") >= 0 || str.indexOf("\n") >= 0) {
            return "\"" + str.replace(/"/g, "\"\"") + "\"";
        }
        return str;
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

        ComboBox {
            id: rangeCombo
            Kirigami.FormData.label: "Data Range:"
            model: ["1D", "5D", "1M", "6M", "YTD", "1Y", "5Y", "Max"]
            onActivated: configPage.cfg_chartRange = currentText
            Component.onCompleted: {
                var idx = indexOfValue(configPage.cfg_chartRange)
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

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Panel View"
        }

        CheckBox {
            id: hidePercentSwitch
            Kirigami.FormData.label: "Stock Change Percentage:"
            text: "Hide stock change percentage"
        }

        CheckBox {
            id: hideTimestampsSwitch
            Kirigami.FormData.label: "Update Timestamps:"
            text: "Hide update timestamps"
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Colors"
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

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Portfolio Tracking"
        }

        CheckBox {
            id: portfolioModeSwitch
            Kirigami.FormData.label: "Portfolio Mode:"
            text: "Show profit/loss calculations"
        }

        TextField {
            id: portfolioTickerField
            Kirigami.FormData.label: "Ticker:"
            placeholderText: "e.g., AAPL"
            Layout.preferredWidth: 120
        }

        SpinBox {
            id: portfolioSharesSpin
            Kirigami.FormData.label: "Shares:"
            from: 0
            to: 999999
            editable: true
        }

        TextField {
            id: portfolioCostField
            Kirigami.FormData.label: "Average Cost:"
            placeholderText: "0.00"
            validator: DoubleValidator { bottom: 0; decimals: 2 }
        }

        RowLayout {
            spacing: Kirigami.Units.smallSpacing
            Kirigami.FormData.label: "Actions:"

            Button {
                text: "Add/Update"
                onClicked: {
                    if (portfolioTickerField.text.trim() !== "" && portfolioSharesSpin.value > 0) {
                        var portfolio = safeParsePortfolio(configPage.cfg_portfolioData);
                        var ticker = portfolioTickerField.text.trim().toUpperCase();
                        var found = false;
                        for (var i = 0; i < portfolio.length; i++) {
                            if (portfolio[i].ticker === ticker) {
                                portfolio[i].shares = portfolioSharesSpin.value;
                                portfolio[i].averageCost = parseFloat(portfolioCostField.text) || 0;
                                portfolio[i].lastModifiedDate = new Date().toISOString();
                                found = true;
                                break;
                            }
                        }
                        if (!found) {
                            portfolio.push({
                                ticker: ticker,
                                shares: portfolioSharesSpin.value,
                                averageCost: parseFloat(portfolioCostField.text) || 0,
                                addedDate: new Date().toISOString()
                            });
                        }
                        configPage.cfg_portfolioData = JSON.stringify(portfolio);
                        portfolioListText.text = formatPortfolioList(portfolio);
                        portfolioTickerField.text = "";
                        portfolioSharesSpin.value = 0;
                        portfolioCostField.text = "";
                    }
                }
            }

            Button {
                text: "Remove"
                onClicked: {
                    if (portfolioTickerField.text.trim() !== "") {
                        var portfolio = safeParsePortfolio(configPage.cfg_portfolioData);
                        var ticker = portfolioTickerField.text.trim().toUpperCase();
                        portfolio = portfolio.filter(function(item) { return item.ticker !== ticker; });
                        configPage.cfg_portfolioData = JSON.stringify(portfolio);
                        portfolioListText.text = formatPortfolioList(portfolio);
                    }
                }
            }

            Button {
                text: "Export CSV"
                onClicked: {
                    var portfolio = safeParsePortfolio(configPage.cfg_portfolioData);
                    if (portfolio.length === 0) {
                        portfolioListText.text = "No portfolio data to export.";
                        return;
                    }
                    var csv = "Ticker,Shares,Average Cost,Added Date\n";
                    for (var i = 0; i < portfolio.length; i++) {
                        csv += escapeCsvField(portfolio[i].ticker) + "," + escapeCsvField(portfolio[i].shares) + "," + escapeCsvField(portfolio[i].averageCost) + "," + escapeCsvField(portfolio[i].addedDate) + "\n";
                    }
                    portfolioListText.text = "CSV Content (copy manually):\n" + csv;
                }
            }
        }

        Label {
            id: portfolioListText
            text: ""
            font.pixelSize: 11
            color: Kirigami.Theme.neutralTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
            Component.onCompleted: {
                var portfolio = safeParsePortfolio(configPage.cfg_portfolioData);
                text = formatPortfolioList(portfolio);
            }
        }

        Item {
            Kirigami.FormData.isSection: true
            Kirigami.FormData.label: "Symbol Search Helper"
        }

        TextField {
            id: searchField
            Kirigami.FormData.label: "Quick Search:"
            placeholderText: "e.g. Tesla, THY, NVIDIA..."
            onTextChanged: searchTimer.restart()
        }

        Label {
            id: searchHelpText
            text: "Type to find symbols..."
            font.pixelSize: 11
            color: Kirigami.Theme.neutralTextColor
            wrapMode: Text.WordWrap
            Layout.fillWidth: true
        }

        Timer {
            id: searchTimer
            interval: 800
            repeat: false
            onTriggered: configPage.searchSymbols(searchField.text)
        }
    }
}
