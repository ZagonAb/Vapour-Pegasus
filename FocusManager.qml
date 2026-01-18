import QtQuick 2.15

QtObject {
    id: focusManager

    // Focus state properties
    property string currentFocus: "gameList"
    property string currentView: "home"

    // View references - ahora solo tenemos un filterListView
    property var homeView: null
    property var detailsView: null
    property var gameListView: null
    property var filterListView: null  // Cambiado de filterSelector a filterListView

    // Set focus to a specific element
    function setFocus(elementName) {
        currentFocus = elementName
        console.log("Setting focus to:", elementName)

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

    // Switch view
    function switchView(viewName) {
        currentView = viewName
        console.log("Switching view to:", viewName)

        if (homeView) homeView.visible = (viewName === "home")
            if (detailsView) detailsView.visible = (viewName === "details")

                // Set appropriate focus
                if (viewName === "home") {
                    setFocus("gameList")
                } else if (viewName === "details") {
                    setFocus("details")
                }
    }

    // Handle back navigation
    function handleBack() {
        console.log("handleBack - currentView:", currentView, "currentFocus:", currentFocus)

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

    // Handle navigation down
    function handleDown() {
        console.log("handleDown - currentView:", currentView, "currentFocus:", currentFocus)

        if (currentView === "home") {
            if (currentFocus === "gameList") {
                setFocus("filterSelector")
                return true
            }
        }
        return false
    }

    // Handle navigation up
    function handleUp() {
        console.log("handleUp - currentView:", currentView, "currentFocus:", currentFocus)

        if (currentView === "home") {
            if (currentFocus === "filterSelector") {
                setFocus("gameList")
                return true
            }
        }
        return false
    }

    // Enter collections view
    function enterCollectionsView() {
        console.log("Entering collections view")
        // El foco ya está en filterSelector, solo cambiamos el modelo
    }

    // Exit collections view
    function exitCollectionsView() {
        console.log("Exiting collections view")
        // El foco ya está en filterSelector, solo cambiamos el modelo
    }
}
