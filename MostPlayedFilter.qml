import QtQuick 2.15
import SortFilterProxyModel 0.2

SortFilterProxyModel {
    sourceModel: api.allGames
    filters: ExpressionFilter {
        expression: {
            return model.playTime > 0
        }
    }
    sorters: RoleSorter {
        roleName: "playTime"
        sortOrder: Qt.DescendingOrder
    }
}
