import QtQuick
import org.kde.plasma.configuration

ConfigModel {
    ConfigCategory {
        name: "General"
        icon: "configure"
        source: "configGeneral.qml"
    }
    ConfigCategory {
        name: "Find ticker symbol"
        icon: "search"
        source: "configSearch.qml"
    }
    ConfigCategory {
        name: "Portfolio Tracking(WIP)"
        icon: "office-chart-line"
        source: "configPortfolio.qml"
    }
    ConfigCategory {
        name: "Appearance"
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
}
