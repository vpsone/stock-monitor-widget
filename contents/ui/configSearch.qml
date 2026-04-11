import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import org.kde.kirigami as Kirigami

Item {
    id: page

    property string cfg_ticker
    property string cfg_multiTickers
    property bool cfg_isMultiMode

    ListModel {
        id: resultsModel
    }

    function searchSymbols(query) {
        if (query.trim().length < 1) {
            resultsModel.clear();
            searchHelpText.text = "Enter a search term.";
            return;
        }
        searchHelpText.text = "Searching...";
        resultsModel.clear();
        
        var xhr = new XMLHttpRequest();
        var url = "https://query2.finance.yahoo.com/v1/finance/search?q=" + encodeURIComponent(query);
        xhr.onreadystatechange = function() {
            if (xhr.readyState === XMLHttpRequest.DONE) {
                if (xhr.status === 200) {
                    try {
                        var res = JSON.parse(xhr.responseText);
                        var results = res.quotes || [];
                        if (results.length === 0) {
                            searchHelpText.text = "No symbols found.";
                            return;
                        }
                        searchHelpText.text = "Suggestions:";
                        for (var i = 0; i < Math.min(results.length, 10); i++) {
                            var item = results[i];
                            if (item.symbol) {
                                resultsModel.append({
                                    "symbol": item.symbol,
                                    "name": item.shortname || item.longname || item.symbol
                                });
                            }
                        }
                    } catch (e) {
                        searchHelpText.text = "Error parsing search results.";
                    }
                } else {
                    searchHelpText.text = "Search failed (HTTP " + xhr.status + ").";
                }
            }
        }
        xhr.open("GET", url);
        xhr.send();
    }

    ScrollView {
        anchors.fill: parent
        anchors.margins: 20
        contentWidth: availableWidth
        clip: true

        Kirigami.FormLayout {
            width: parent.availableWidth

            RowLayout {
                Kirigami.FormData.label: "Search:"
                Layout.fillWidth: true

                TextField {
                    id: searchField
                    placeholderText: "e.g. Tesla, AAPL..."
                    Layout.fillWidth: true
                    onAccepted: page.searchSymbols(searchField.text)
                    Keys.onReturnPressed: {
                        event.accepted = true;
                        page.searchSymbols(searchField.text);
                    }
                    Keys.onEnterPressed: {
                        event.accepted = true;
                        page.searchSymbols(searchField.text);
                    }
                }
                
                Button {
                    text: "Search"
                    icon.name: "search"
                    onClicked: page.searchSymbols(searchField.text)
                }
            }

            Label {
                id: searchHelpText
                text: "Type to find symbols and click Search."
                font.pixelSize: 11
                color: Kirigami.Theme.neutralTextColor
                wrapMode: Text.WordWrap
                Layout.fillWidth: true
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: Kirigami.Units.smallSpacing

                Repeater {
                    model: resultsModel
                    delegate: RowLayout {
                        Layout.fillWidth: true
                        
                        Label {
                            text: "<b>" + model.symbol + "</b> - " + model.name
                            Layout.fillWidth: true
                            elide: Text.ElideRight
                        }

                        Button {
                            text: "SS"
                            ToolTip.visible: hovered
                            ToolTip.text: "Add to Single Stock"
                            onClicked: {
                                page.cfg_ticker = model.symbol;
                                page.cfg_isMultiMode = false;
                                searchHelpText.text = "Set " + model.symbol + " as Single Stock.";
                            }
                        }

                        Button {
                            text: "MSL"
                            ToolTip.visible: hovered
                            ToolTip.text: "Add to Multi Stock List"
                            onClicked: {
                                var currentList = page.cfg_multiTickers ? page.cfg_multiTickers.trim() : "";
                                if (currentList === "") {
                                    page.cfg_multiTickers = model.symbol;
                                } else {
                                    var arr = currentList.split(",").map(function(s) { return s.trim(); });
                                    if (arr.indexOf(model.symbol) === -1) {
                                        page.cfg_multiTickers = currentList + ", " + model.symbol;
                                    }
                                }
                                page.cfg_isMultiMode = true;
                                searchHelpText.text = "Added " + model.symbol + " to Multi Stock List.";
                            }
                        }
                    }
                }
            }
        }
    }
}
