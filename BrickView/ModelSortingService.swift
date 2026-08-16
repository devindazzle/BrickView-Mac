//
//  ModelSortingService.swift
//  BrickView
//
//  Created by Kim Pedersen on 16/08/2026.
//

//
//  Purpose:
//  Sorts BrickView models according to the selected sort criterion
//  and sort order.
//
//  The service is UI-independent and does not modify the source
//  model collection.
//

import Foundation

struct ModelSortingService {
    func sort(
        _ models: [Model],
        by option: ModelSortOption,
        order: ModelSortOrder
    ) -> [Model] {
        var sortedModels: [Model]

        switch option {
        case .filename:
            sortedModels = models.sorted {
                $0.filename.localizedStandardCompare($1.filename) == .orderedAscending
            }

        case .creationDate:
            sortedModels = models.sorted {
                compareDates(
                    $0.creationDate,
                    $1.creationDate
                )
            }

        case .modificationDate:
            sortedModels = models.sorted {
                compareDates(
                    $0.modificationDate,
                    $1.modificationDate
                )
            }
        }

        if order == .ascending {
            return sortedModels
        }

        return sortedModels.reversed()
    }

    private func compareDates(
        _ lhs: Date?,
        _ rhs: Date?
    ) -> Bool {
        switch (lhs, rhs) {
        case let (lhsDate?, rhsDate?):
            return lhsDate < rhsDate

        case (nil, _?):
            return false

        case (_?, nil):
            return true

        case (nil, nil):
            return false
        }
    }
}
