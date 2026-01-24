import QtQuick 2.15
import SortFilterProxyModel 0.2

SortFilterProxyModel {
    sourceModel: api.allGames
    filters: ExpressionFilter {
        expression: {
            var lp = model.lastPlayed
            if (!lp) return false
                if (typeof lp.getTime !== "function") return false
                    return lp.getTime() > 0
        }
    }
    sorters: RoleSorter {
        roleName: "lastPlayed"
        sortOrder: Qt.DescendingOrder
    }
}
