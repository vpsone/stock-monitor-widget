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
        name: "Panel view"
        icon: "view-list-details"
        source: "configPanel.qml"
    }
    ConfigCategory {
        name: "Portfolio Tracking"
        icon: "office-chart-line"
        source: "configPortfolio.qml"
    }
    ConfigCategory {
        name: "Appearence"
        icon: "preferences-desktop-color"
        source: "configAppearance.qml"
    }
}
