import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property alias cfg_showPortfolioMode: portfolioModeSwitch.checked
    property string cfg_portfolioData

    // Every purchase is kept as its own lot (same ticker can appear more than once, e.g.
    // bought at different prices on different dates). The widget shows each lot's own
    // profit/loss separately rather than blending them into one average.
    property var portfolioList: []

    Component.onCompleted: page.refreshPortfolioList()

    function safeParsePortfolio(data) {
        if (!data) return [];
        try {
            return JSON.parse(data);
        } catch (e) {
            console.error("Failed to parse portfolio data:", e);
            return [];
        }
    }

    // Parses a price typed with either "." or "," as the decimal separator, regardless of
    // the system locale (avoids the DoubleValidator/parseFloat locale mismatch where a
    // locale using "," for decimals gets silently truncated by JS's locale-independent parseFloat).
    function parseLocaleNumber(text) {
        if (!text) return NaN;
        var str = String(text).trim();
        var lastComma = str.lastIndexOf(",");
        var lastDot = str.lastIndexOf(".");
        if (lastComma !== -1 && lastDot !== -1) {
            // Both separators present: whichever comes last is the decimal separator,
            // the other one is a thousands grouping separator to strip.
            if (lastComma > lastDot) {
                str = str.replace(/\./g, "").replace(",", ".");
            } else {
                str = str.replace(/,/g, "");
            }
        } else if (lastComma !== -1) {
            // Only a comma: treat it as the decimal separator (e.g. "50,21")
            str = str.replace(",", ".");
        }
        return parseFloat(str);
    }

    function escapeCsvField(val) {
        var str = String(val);
        if (str.indexOf(",") >= 0 || str.indexOf("\"") >= 0 || str.indexOf("\n") >= 0) {
            return "\"" + str.replace(/"/g, "\"\"") + "\"";
        }
        return str;
    }

    function refreshPortfolioList() {
        page.portfolioList = page.safeParsePortfolio(page.cfg_portfolioData);
    }

    function addLot() {
        if (portfolioTickerField.text.trim() === "" || portfolioSharesSpin.value <= 0) return;
        var portfolio = page.safeParsePortfolio(page.cfg_portfolioData);
        portfolio.push({
            ticker: portfolioTickerField.text.trim().toUpperCase(),
            shares: portfolioSharesSpin.value,
            averageCost: page.parseLocaleNumber(portfolioCostField.text) || 0,
            addedDate: new Date().toISOString()
        });
        page.cfg_portfolioData = JSON.stringify(portfolio);
        page.refreshPortfolioList();
        portfolioTickerField.text = "";
        portfolioSharesSpin.value = 0;
        portfolioCostField.text = "";
    }

    // Removes a single lot by its position in portfolioList (not by ticker, since a ticker
    // can have several lots).
    function removeLot(index) {
        var portfolio = page.safeParsePortfolio(page.cfg_portfolioData);
        portfolio.splice(index, 1);
        page.cfg_portfolioData = JSON.stringify(portfolio);
        page.refreshPortfolioList();
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        ColumnLayout {
            width: parent.availableWidth
            spacing: Kirigami.Units.largeSpacing

            Kirigami.FormLayout {
                Layout.fillWidth: true

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
                    // Plain digits + a single "." or "," decimal separator. Deliberately not a
                    // DoubleValidator: on locales where "," is the decimal separator (e.g. es_AR),
                    // DoubleValidator treats "." as a thousands separator and rewrites the field
                    // into locale-formatted scientific notation (e.g. "50.21" -> "5,02E+03") on
                    // focus loss, which then gets mis-parsed. See page.parseLocaleNumber().
                    validator: RegularExpressionValidator { regularExpression: /^\d*[.,]?\d*$/ }
                }

                RowLayout {
                    spacing: Kirigami.Units.smallSpacing
                    Kirigami.FormData.label: "Actions:"

                    Button {
                        text: "Add Lot"
                        onClicked: page.addLot()
                    }

                    Button {
                        text: "Export CSV"
                        onClicked: {
                            if (page.portfolioList.length === 0) {
                                csvOutput.text = "No portfolio data to export.";
                                return;
                            }
                            var csv = "Ticker,Shares,Average Cost,Added Date\n";
                            for (var i = 0; i < page.portfolioList.length; i++) {
                                var lot = page.portfolioList[i];
                                csv += page.escapeCsvField(lot.ticker) + "," + page.escapeCsvField(lot.shares) + "," + page.escapeCsvField(lot.averageCost) + "," + page.escapeCsvField(lot.addedDate) + "\n";
                            }
                            csvOutput.text = csv;
                        }
                    }
                }

                Label {
                    text: "Each purchase is its own lot — buying more of the same ticker at a different price adds a new lot instead of overwriting the old one."
                    font.pixelSize: 10
                    font.italic: true
                    opacity: 0.7
                    wrapMode: Text.WordWrap
                    Layout.fillWidth: true
                    Layout.preferredWidth: 300
                }
            }

            Kirigami.Separator { Layout.fillWidth: true }

            Label {
                text: "Your Lots"
                font.bold: true
                Layout.fillWidth: true
            }

            Label {
                visible: page.portfolioList.length === 0
                text: "No holdings added yet."
                opacity: 0.7
                font.pixelSize: 11
            }

            Repeater {
                model: page.portfolioList
                delegate: RowLayout {
                    Layout.fillWidth: true
                    Label {
                        Layout.fillWidth: true
                        elide: Text.ElideRight
                        font.pixelSize: 11
                        text: modelData.ticker + ":  " + modelData.shares + " shares @ $" + Number(modelData.averageCost).toFixed(2)
                              + (modelData.addedDate ? "   (" + Qt.formatDateTime(new Date(modelData.addedDate), "dd MMM yyyy") + ")" : "")
                    }
                    Button {
                        text: "Remove"
                        onClicked: page.removeLot(index)
                    }
                }
            }

            Label {
                id: csvOutput
                text: ""
                font.pixelSize: 10
                font.family: "monospace"
                color: Kirigami.Theme.neutralTextColor
                wrapMode: Text.WordWrap
                visible: text !== ""
                Layout.fillWidth: true
            }
        }
    }
}
