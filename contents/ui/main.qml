import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore

PlasmoidItem {
    id: root

    // --- CONFIGURATION ---
    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    // Detect where we are (Panel vs Desktop) to switch views
    preferredRepresentation: (Plasmoid.formFactor === PlasmaCore.Types.Horizontal || Plasmoid.formFactor === PlasmaCore.Types.Vertical)
    ? Plasmoid.CompactRepresentation
    : Plasmoid.FullRepresentation


    property string singleTicker: Plasmoid.configuration.ticker
    property bool isMultiMode: Plasmoid.configuration.isMultiMode
    property string multiTickers: Plasmoid.configuration.multiTickers
    property string chartRange: Plasmoid.configuration.chartRange

    // Time Limits Config
    property bool limitHours: Plasmoid.configuration.limitHours
    property int startHour: Plasmoid.configuration.startHour
    property int startMinute: Plasmoid.configuration.startMinute
    property int endHour: Plasmoid.configuration.endHour
    property int endMinute: Plasmoid.configuration.endMinute

    // Internal Properties for Single View
    property string singleCompanyName: "Loading..."
    property string currentPrice: "---"
    property string priceChange: "+0.00"
    property string percentChange: "+0.00%"
    property var chartDataPoints: []
    property double previousClose: 0.0
    property bool isPositive: true
    property string currencySym: ""

    property color positiveColor: "#4cd964"
    property color negativeColor: "#ff3b30"
    property color bgColor: "#1a1a1a"

    ListModel { id: stockModel }

    function getCurrencySymbol(code) {
        // Fix: Return empty string if code is missing or literal "null"
        if (!code || code === "null") return "";

        const symbols = {
            "USD": "$", "EUR": "€", "GBP": "£", "INR": "₹", "JPY": "¥",
            "CNY": "¥", "KRW": "₩", "RUB": "₽"
        };
        return symbols[code] || code + " ";
    }

    // --- NEW HELPER: GET API PARAMETERS BASED ON CONFIG ---
    function getApiParams() {
        // Yahoo Finance requires specific intervals for specific ranges
        // to return valid data and look good.
        switch (root.chartRange) {
            case "1D":  return "range=1d&interval=2m";
            case "5D":  return "range=5d&interval=15m";
            case "1M":  return "range=1mo&interval=60m"; // '1mo' is Yahoo syntax
            case "6M":  return "range=6mo&interval=1d";
            case "YTD": return "range=ytd&interval=1d";
            case "1Y":  return "range=1y&interval=1d";
            case "5Y":  return "range=5y&interval=1wk";
            case "Max": return "range=max&interval=1mo";
            default:    return "range=1d&interval=2m";
        }
    }

    function refreshData() {
        if (root.isMultiMode) {
            fetchMultiStocks();
        } else {
            fetchSingleStock(root.singleTicker);
        }
    }

    // --- NEW CHECK: IS MARKET OPEN? ---
    function checkTimeAndRefresh() {
        // 1. Always check weekend first (optional, but saves battery)
        var d = new Date();
        var day = d.getDay();
        // 0=Sun, 6=Sat. Crypto (BTC) runs 24/7, so you might want to skip this check for crypto.
        // Assuming stocks for now:
        if (day === 0 || day === 6) {
            // Optional: Allow update if ticker contains "-USD" (crypto)?
            // For now, let's strictly follow the rule:
            // return;
        }

        // 2. Check Time Window if enabled
        if (root.limitHours) {
            var nowHour = d.getHours();
            var nowMin = d.getMinutes();
            var currentTimeVal = nowHour * 60 + nowMin;

            var startTimeVal = root.startHour * 60 + root.startMinute;
            var endTimeVal = root.endHour * 60 + root.endMinute;

            // If we are BEFORE start OR AFTER end, stop.
            if (currentTimeVal < startTimeVal || currentTimeVal >= endTimeVal) {
                return; // Do not fetch
            }
        }

        // 3. If passed, refresh
        refreshData();
    }

    function fetchSingleStock(symbol) {
        var xhr = new XMLHttpRequest();
        var url = "https://query1.finance.yahoo.com/v8/finance/chart/" + symbol + "?" + getApiParams();
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                var response = JSON.parse(xhr.responseText);
                processSingleData(response);
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    function fetchMultiStocks() {
        var tickers = root.multiTickers.split(",");
        tickers.forEach(function(tickerSymbol) {
            var cleanSymbol = tickerSymbol.trim();
            if(cleanSymbol === "") return;

            var xhr = new XMLHttpRequest();
            var url = "https://query1.finance.yahoo.com/v8/finance/chart/" + cleanSymbol + "?" + getApiParams();
            xhr.onreadystatechange = function() {
                if (xhr.readyState === XMLHttpRequest.DONE && xhr.status === 200) {
                    var response = JSON.parse(xhr.responseText);
                    processListRow(cleanSymbol, response);
                }
            }
            xhr.open("GET", url);
            xhr.send();
        });
    }

    function processSingleData(json) {
        try {
            var result = json.chart.result[0];
            var meta = result.meta;
            var quotes = result.indicators.quote[0].close;

            root.singleCompanyName = meta.shortName || meta.longName || root.singleTicker;
            root.previousClose = meta.chartPreviousClose;
            root.currencySym = getCurrencySymbol(meta.currency);
            root.currentPrice = root.currencySym + meta.regularMarketPrice.toFixed(2);

            var change = meta.regularMarketPrice - meta.chartPreviousClose;
            root.isPositive = change >= 0;
            root.priceChange = (change > 0 ? "+" : "") + change.toFixed(2);
            root.percentChange = (change > 0 ? "+" : "") + ((change / meta.chartPreviousClose) * 100).toFixed(2) + "%";

            var cleanData = [];
            for (var i = 0; i < quotes.length; i++) {
                if (quotes[i] !== null) cleanData.push(quotes[i]);
            }
            root.chartDataPoints = cleanData;
        } catch (e) { console.log("Error parsing single: " + e); }
    }

    function processListRow(symbol, json) {
        try {
            var result = json.chart.result[0];
            var meta = result.meta;
            var quotes = result.indicators.quote[0].close;

            var current = meta.regularMarketPrice;
            var prev = meta.chartPreviousClose;
            var change = current - prev;
            var pct = (change / prev) * 100;
            var curSym = getCurrencySymbol(meta.currency);

            var cleanData = [];
            for (var i = 0; i < quotes.length; i++) {
                if (quotes[i] !== null) cleanData.push(quotes[i]);
            }

            var itemData = {
                "ticker": symbol,
                "name": meta.shortName || meta.longName || symbol,
                "price": curSym + current.toFixed(2),
                "change": (change > 0 ? "+" : "") + change.toFixed(2),
                "pct": (change > 0 ? "+" : "") + pct.toFixed(2) + "%",
                "isPos": change >= 0,
                "chartPoints": cleanData,
                "prevClose": prev
            };

            var found = false;
            for(var k=0; k<stockModel.count; k++) {
                if(stockModel.get(k).ticker === symbol) {
                    stockModel.set(k, itemData);
                    found = true;
                    break;
                }
            }
            if(!found) stockModel.append(itemData);

        } catch (e) { console.log("Error parsing multi: " + e); }
    }

    onSingleTickerChanged: refreshData()
    onIsMultiModeChanged: { stockModel.clear(); refreshData(); }
    onMultiTickersChanged: { stockModel.clear(); refreshData(); }
    // CHANGED: Update when range changes
    onChartRangeChanged: { stockModel.clear(); refreshData(); }

    Timer {
        interval: Plasmoid.configuration.refreshInterval * 60000
        running: true
        repeat: true
        triggeredOnStart: true
        // CHANGED: Call checkTimeAndRefresh instead of refreshData directly
        onTriggered: root.checkTimeAndRefresh()
    }

    // --- PANEL VIEW (Compact Representation) ---
    compactRepresentation: MouseArea {
        id: compactRoot
        Layout.minimumWidth: panelLayout.implicitWidth
        Layout.minimumHeight: panelLayout.implicitHeight

        onClicked: Plasmoid.expanded = !Plasmoid.expanded

        RowLayout {
            id: panelLayout
            anchors.fill: parent
            spacing: 4 // Space between Icon and the Text Stack

            // Stacked Text Column
            ColumnLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: -1 // Negative spacing keeps them tight together in the panel

                // 1. Top: Ticker Name (Small)
                Text {
                    text: root.singleTicker
                    color: PlasmaCore.Theme.textColor
                    font.pixelSize: 8   // Small font
                    opacity: 0.8        // Slightly dimmed
                    visible: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                    Layout.alignment: Qt.AlignLeft
                }

                // 2. Bottom: Current Price (Colored)
                Text {
                    text: root.currentPrice
                    color: root.isPositive ? root.positiveColor : root.negativeColor
                    // font.bold: true
                    font.pixelSize: 12
                    visible: Plasmoid.formFactor === PlasmaCore.Types.Horizontal
                    Layout.alignment: Qt.AlignLeft
                }
            }
        }
    }

    // --- DESKTOP VIEW (Full Representation) ---

    fullRepresentation: Item {
        Layout.minimumWidth: 190
        Layout.minimumHeight: 170
        // Layout.preferredWidth: 260
        // Layout.preferredHeight: 300

        Rectangle {
            anchors.fill: parent
            color: root.bgColor
            anchors.margins: 10
            radius: 22
            opacity: 1

            Text {
                anchors.centerIn: parent
                text: "Loading..."
                color: "#888888"
                font.pixelSize: 14
                visible: root.isMultiMode && stockModel.count === 0
            }

            Item {
                id: singleView
                visible: !root.isMultiMode
                anchors.fill: parent
                // anchors.margins: 16
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 16
                anchors.bottomMargin: 10

                ColumnLayout {
                    anchors.fill: parent
                    spacing: 0
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 0
                        ColumnLayout {
                            spacing: 2
                            Layout.alignment: Qt.AlignLeft | Qt.AlignTop
                            RowLayout {
                                spacing: 5
                                Text {
                                    text: root.isPositive ? "▲" : "▼"
                                    color: root.isPositive ? root.positiveColor : root.negativeColor
                                    font.pixelSize: 12
                                    Layout.alignment: Qt.AlignVCenter
                                }
                                Text {
                                    text: root.singleTicker
                                    color: "white"
                                    font.bold: true
                                    font.pixelSize: 15
                                    font.family: "Arial"
                                    Layout.alignment: Qt.AlignVCenter
                                    // Add this to prevent it from being too long
                                    elide: Text.ElideRight
                                    // Layout.maximumWidth: 120
                                    Layout.fillWidth: true
                                }
                            }
                            Text {
                                text: root.singleCompanyName
                                color: "#888888"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                                // Layout.maximumWidth: 120
                            }
                        }
                        Item { Layout.fillWidth: true }
                        ColumnLayout {
                            spacing: 0
                            Layout.alignment: Qt.AlignRight | Qt.AlignTop
                            Text {
                                text: root.percentChange
                                color: root.isPositive ? root.positiveColor : root.negativeColor
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignRight
                                font.bold: true
                            }
                            Text {
                                text: root.priceChange
                                color: root.isPositive ? root.positiveColor : root.negativeColor
                                font.pixelSize: 13
                                Layout.alignment: Qt.AlignRight
                                font.bold: true
                            }
                        }
                    }
                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        Layout.topMargin: 10
                        Layout.bottomMargin: 5
                        Canvas {
                            id: singleCanvas
                            anchors.fill: parent
                            renderStrategy: Canvas.Threaded
                            renderTarget: Canvas.Image
                            onPaint: { drawChart(getContext("2d"), width, height, root.chartDataPoints, root.previousClose, root.isPositive, true); }
                            Connections { target: root; function onChartDataPointsChanged() { singleCanvas.requestPaint(); } }
                        }
                    }
                    Text {
                        Layout.alignment: Qt.AlignHCenter
                        text: root.currentPrice
                        color: "white"
                        font.pixelSize: 26
                        font.weight: Font.bold
                    }
                }
            }

            ListView {
                id: multiView
                visible: root.isMultiMode
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.bottomMargin: 16
                anchors.topMargin: 0

                clip: true
                model: stockModel
                spacing: 0

                delegate: Item {
                    width: multiView.width
                    height: 60
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
                                    color: model.isPos ? root.positiveColor : root.negativeColor
                                    font.pixelSize: 10
                                }
                                Text {
                                    text: model.ticker
                                    color: "white"
                                    // font.bold: true
                                    font.pixelSize: 14
                                }
                            }
                            Text {
                                text: model.name
                                color: "#888888"
                                font.pixelSize: 10
                                elide: Text.ElideRight
                                Layout.fillWidth: true
                            }
                        }
                        Item {
                            visible: parent.width > 220
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Canvas {
                                id: sparkLine
                                anchors.fill: parent
                                renderStrategy: Canvas.Threaded
                                renderTarget: Canvas.Image
                                onPaint: { drawChart(getContext("2d"), width, height, model.chartPoints, model.prevClose, model.isPos, false); }
                                Component.onCompleted: sparkLine.requestPaint()
                                Connections {
                                    target: stockModel
                                    function onDataChanged() { sparkLine.requestPaint() }
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
                            spacing: 2
                            Text {
                                text: model.price
                                color: "white"
                                // font.bold: true
                                font.pixelSize: 14
                                Layout.alignment: Qt.AlignRight
                            }
                            Text {
                                text: model.change
                                color: model.isPos ? root.positiveColor : root.negativeColor
                                font.pixelSize: 11
                                Layout.alignment: Qt.AlignRight
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
        }
    }

    function drawChart(ctx, w, h, data, prevClose, isPos, drawBackground) {
        ctx.clearRect(0, 0, w, h);
        if (!data || data.length < 2) return;
        var minVal = Math.min(...data);
        var maxVal = Math.max(...data);
        var range = maxVal - minVal;
        if (range === 0) range = 1;
        var padding = range * (drawBackground ? 0.1 : 0.05);
        minVal -= padding;
        maxVal += padding;
        range = maxVal - minVal;
        function getY(val) { return h - ((val - minVal) / range * h); }

        if (drawBackground) {
            var prevY = getY(prevClose);
            ctx.beginPath();
            ctx.strokeStyle = "#333333";
            ctx.lineWidth = 1;
            ctx.setLineDash([4, 4]);
            ctx.moveTo(0, prevY);
            ctx.lineTo(w, prevY);
            ctx.stroke();
            ctx.setLineDash([]);
        }

        ctx.beginPath();
        var stepX = w / (data.length - 1);
        ctx.moveTo(0, getY(data[0]));
        for (var i = 1; i < data.length; i++) {
            ctx.lineTo(i * stepX, getY(data[i]));
        }

        ctx.lineJoin = "round";
        ctx.lineWidth = 2;
        ctx.strokeStyle = isPos ? root.positiveColor : root.negativeColor;
        ctx.stroke();

        if (drawBackground) {
            ctx.lineTo(w, h);
            ctx.lineTo(0, h);
            ctx.closePath();
            var gradient = ctx.createLinearGradient(0, 0, 0, h);
            var baseColor = isPos ? root.positiveColor : root.negativeColor;
            gradient.addColorStop(0.0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.3));
            gradient.addColorStop(1.0, Qt.rgba(baseColor.r, baseColor.g, baseColor.b, 0.0));
            ctx.fillStyle = gradient;
            ctx.fill();
        }
    }
}
