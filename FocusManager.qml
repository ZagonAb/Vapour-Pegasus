import QtQuick 2.15

QtObject {
    id: focusManager

    property string currentFocus: "gameList"
    property string currentView: "home"
    property var homeView: null
    property var detailsView: null
    property var gameListView: null
    property var filterListView: null

    function setFocus(elementName) {
        currentFocus = elementName

        switch(elementName) {
            case "gameList":
                if (gameListView) {
                    gameListView.focus = true
                    if (filterListView) filterListView.focus = false
                }
                break

            case "filterSelector":
                if (filterListView) {
                    filterListView.focus = true
                    if (gameListView) gameListView.focus = false
                }
                break

            case "details":
                if (detailsView) {
                    detailsView.focus = true
                    if (gameListView) gameListView.focus = false
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
}
