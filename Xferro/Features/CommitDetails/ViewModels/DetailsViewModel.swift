//
//  DetailsViewModel.swift
//  Xferro
//
//  Created by Taha Bebek on 2/15/25.
//

import Observation

@Observable final class DetailsViewModel {
    var detailInfo: DetailInfo

    init(detailInfo: DetailInfo) {
        self.detailInfo = detailInfo
    }
}
