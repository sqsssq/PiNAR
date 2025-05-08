//
//  ViewModel.swift
//  PosterAR
//
//  Created by Qing Shi on 2025/4/24.
//

import Foundation
import Observation

enum FlowState {
    case idle
    case intro
    case projectFlying
    case update
}

@Observable
class ViewModel {
    var flowState = FlowState.idle;
}
