import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
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
                    text: "Export CSV"
                    onClicked: {
                        var portfolio = page.safeParsePortfolio(page.cfg_portfolioData);
                        if (portfolio.length === 0) {
                            portfolioListText.text = "No portfolio data to export.";
                            return;
                        }
                        var csv = "Ticker,Shares,Average Cost,Added Date\n";
                        for (var i = 0; i < portfolio.length; i++) {
                            csv += page.escapeCsvField(portfolio[i].ticker) + "," + page.escapeCsvField(portfolio[i].shares) + "," + page.escapeCsvField(portfolio[i].averageCost) + "," + page.escapeCsvField(portfolio[i].addedDate) + "\n";
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
                    var portfolio = page.safeParsePortfolio(page.cfg_portfolioData);
                    text = page.formatPortfolioList(portfolio);
                }
            }
        }
    }
}
