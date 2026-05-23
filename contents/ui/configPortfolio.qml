import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Dialogs
import org.kde.kirigami as Kirigami

Item {
    id: page

    property alias cfg_showPortfolioMode: portfolioModeSwitch.checked
    property string cfg_portfolioData

    function formatPortfolioList(portfolio) {
        if (!portfolio || portfolio.length === 0) {
            return "No holdings added yet.";
        }
        var displayStr = "Current Holdings:\n";
        for (var i = 0; i < portfolio.length; i++) {
            var commissionText = portfolio[i].commission ? (" + commission " + portfolio[i].commission.toFixed(2)) : "";
            displayStr += "• " + portfolio[i].ticker + ": " + portfolio[i].shares + " shares @ " + portfolio[i].averageCost.toFixed(2) + commissionText + "\n";
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

    function buildYahooExportCsv(portfolio) {
        var csv = "Symbol,Quantity,Purchase Price,Commission,Trade Date,Transaction Type\n";
        for (var i = 0; i < portfolio.length; i++) {
            var item = portfolio[i] || {};
            var tradeDate = item.addedDate || item.lastModifiedDate || new Date().toISOString();
            csv += page.escapeCsvField(item.ticker || "") + "," +
                   page.escapeCsvField(item.shares || 0) + "," +
                   page.escapeCsvField(item.averageCost || 0) + "," +
                   page.escapeCsvField(item.commission || 0) + "," +
                   page.escapeCsvField(tradeDate) + ",BUY\n";
        }
        return csv;
    }

    function parseYahooCsv(csvText) {
        if (!csvText) return [];
        var lines = csvText.split(/\r?\n/);
        var portfolio = [];
        // Split by comma, respecting quoted fields
        var splitRE = /,(?=(?:[^"]*"[^"]*")*[^"]*$)/;

        if (lines.length < 2) return [];

        var headers = lines[0].split(splitRE).map(function(col) {
            return col.replace(/^"|"$/g, "").trim().toLowerCase();
        });

        function headerIndex(names) {
            for (var n = 0; n < names.length; n++) {
                var idx = headers.indexOf(names[n]);
                if (idx >= 0) return idx;
            }
            return -1;
        }

        var symbolIdx = headerIndex(["symbol", "ticker"]);
        var sharesIdx = headerIndex(["quantity", "shares"]);
        var priceIdx = headerIndex(["purchase price", "avg cost", "average cost"]);
        var commissionIdx = headerIndex(["commission"]);
        var dateIdx = headerIndex(["trade date", "date added", "date"]);
        var typeIdx = headerIndex(["transaction type", "type"]);

        if (symbolIdx < 0 || sharesIdx < 0 || priceIdx < 0) {
            console.error("Yahoo CSV: missing required columns");
            return [];
        }
        
        for (var i = 1; i < lines.length; i++) {
            var line = lines[i].trim();
            if (!line) continue;
            
            var cols = line.split(splitRE);
            for (var j = 0; j < cols.length; j++) {
                cols[j] = cols[j].replace(/^"|"$/g, "").replace(/""/g, '"');
            }
            
            var txnType = typeIdx >= 0 ? (cols[typeIdx] || "").trim().toUpperCase() : "BUY";
            if (txnType && txnType !== "BUY") continue;

            var ticker = (cols[symbolIdx] || "").trim().toUpperCase();
            if (!ticker) continue;
            
            var shares = parseFloat(cols[sharesIdx]) || 0;
            var avgCost = parseFloat(cols[priceIdx]) || 0;
            var commission = commissionIdx >= 0 ? (parseFloat(cols[commissionIdx]) || 0) : 0;
            var date = dateIdx >= 0 ? (cols[dateIdx] || new Date().toISOString()) : new Date().toISOString();
            
            portfolio.push({
                ticker: ticker,
                shares: shares,
                averageCost: avgCost,
                commission: commission,
                addedDate: date
            });
        }
        return portfolio;
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        Kirigami.FormLayout {
            width: parent.availableWidth

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
                            var portfolio = page.safeParsePortfolio(page.cfg_portfolioData);
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
                            page.cfg_portfolioData = JSON.stringify(portfolio);
                            portfolioListText.text = page.formatPortfolioList(portfolio);
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
                            var portfolio = page.safeParsePortfolio(page.cfg_portfolioData);
                            var ticker = portfolioTickerField.text.trim().toUpperCase();
                            portfolio = portfolio.filter(function(item) { return item.ticker !== ticker; });
                            page.cfg_portfolioData = JSON.stringify(portfolio);
                            portfolioListText.text = page.formatPortfolioList(portfolio);
                        }
                    }
                }

                Button {
                    text: "Export Yahoo CSV"
                    onClicked: {
                        var portfolio = page.safeParsePortfolio(page.cfg_portfolioData);
                        if (portfolio.length === 0) {
                            portfolioListText.text = "No portfolio data to export.";
                            return;
                        }
                        var csv = page.buildYahooExportCsv(portfolio);
                        portfolioListText.text = "Yahoo-compatible CSV (copy manually):\n" + csv;
                    }
                }
                Button {
                    text: "Import Yahoo CSV (Overwrite)"
                    onClicked: {
                        importYahooDialog.open();
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
                    var portfolio = page.safeParsePortfolio(page.cfg_portfolioData);
                    text = page.formatPortfolioList(portfolio);
                }
            }
            FileDialog {
                id: importYahooDialog
                title: "Import your Yahoo Finance Portfolio CSV"
                nameFilters: ["CSV files (*.csv)"]
                onAccepted: {
                    var fileUrl = importYahooDialog.selectedFile;
                    if (!fileUrl) return;
                    
                    var xhr = new XMLHttpRequest();
                    xhr.open("GET", fileUrl);
                    xhr.onreadystatechange = function() {
                        if (xhr.readyState !== XMLHttpRequest.DONE) return;
                        if (xhr.status === 0 || (xhr.status >= 200 && xhr.status < 400)) {
                            var csvText = xhr.responseText;
                            var importedPortfolio = page.parseYahooCsv(csvText);
                            
                            if (importedPortfolio.length === 0) {
                                portfolioListText.text = "No valid holdings found in CSV.";
                                return;
                            }
                            
                            page.cfg_portfolioData = JSON.stringify(importedPortfolio);
                            portfolioListText.text = "Replaced existing portfolio with " + importedPortfolio.length + " holdings from Yahoo CSV:\n" + page.formatPortfolioList(importedPortfolio);
                        } else {
                            console.error("Failed to read file:", xhr.status);
                            portfolioListText.text = "Error importing file. Check console.";
                        }
                    };
                    xhr.send();
                }
            }
        }
    }
}