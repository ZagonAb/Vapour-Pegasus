import QtQuick 2.15

QtObject {
    id: focusManager

    property string currentFocus: "gameList"
    property string currentView: "home"
    property var homeView: null
    property var detailsView: null
    property var gameListView: null
    property var gameGridView: null
    property var filterListView: null
    property var themeRoot: null

    function setFocus(elementName) {
            console.log("FocusManager: Setting focus to", elementName, "isGridViewMode:", themeRoot ? themeRoot.isGridViewMode : "no themeRoot")
            currentFocus = elementName

            switch(elementName) {
                case "gameList":
                    var isGridMode = themeRoot ? themeRoot.isGridViewMode : false

                    if (isGridMode && gameGridView) {
                        console.log("Setting focus to GridView")
                        gameGridView.forceActiveFocus()
                        if (gameListView) gameListView.focus = false
                    } else if (gameListView) {
                        console.log("Setting focus to ListView")
                        gameListView.forceActiveFocus()
                        if (gameGridView) gameGridView.focus = false
                    }
                    if (filterListView) filterListView.focus = false
                        break

            case "filterSelector":
                if (filterListView) {
                    console.log("Setting focus to filterListView")
                    filterListView.forceActiveFocus()
                    if (gameListView) gameListView.focus = false
                        if (gameGridView) gameGridView.focus = false
                }
                break

            case "details":
                if (detailsView) {
                    console.log("Setting focus to detailsView")
                    detailsView.forceActiveFocus()
                    if (gameListView) gameListView.focus = false
                        if (gameGridView) gameGridView.focus = false
                            if (filterListView) filterListView.focus = false
                }
                break
        }
    }

    function switchView(viewName) {
        currentView = viewName

        if (homeView) homeView.visible = (viewName === "home")
            if (detailsView) detailsView.visible = (viewName === "details")

                if (viewName === "home") {
                    setFocus("gameList")
                } else if (viewName === "details") {
                    setFocus("details")
                }
    }

    function handleBack() {
        if (currentView === "details") {
            switchView("home")
                return true
        }

        if (currentFocus === "filterSelector") {
            setFocus("gameList")
            return true
        }

        return false
    }

    function handleDown() {
        if (currentView === "home") {
            if (currentFocus === "gameList") {
                if (homeView.isGridViewMode) {
                    return false
                }
                setFocus("filterSelector")
                return true
            }
        }
        return false
    }

    function handleUp() {
        if (currentView === "home") {
            if (currentFocus === "filterSelector") {
                setFocus("gameList")
                return true
            }
        }
        return false
    }

    function enterCollectionsView() {
    }

    function exitCollectionsView() {
    }

    onGameListViewChanged: {
        if (gameListView && currentFocus === "gameList") {
            gameListView.focus = true
        }
    }

    onGameGridViewChanged: {
        if (gameGridView && currentFocus === "gameList") {
            gameGridView.focus = true
        }
    }
}
