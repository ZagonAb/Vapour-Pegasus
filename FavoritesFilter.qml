import QtQuick 2.15
import SortFilterProxyModel 0.2

SortFilterProxyModel {
    sourceModel: api.allGames
    filters: ValueFilter {
        roleName: "favorite"
        value: true
    }
}
