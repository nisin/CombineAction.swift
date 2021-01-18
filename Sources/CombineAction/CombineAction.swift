//
//  CombineAction.swift
//  CombineAction.swift
//
//  Created by 疋田 将一 on 2021/01/10.
//  Copyright © 2021 Jujit Labo. All rights reserved.
//

import Foundation
import Combine

public final class CombineAction<Input, Output, Failure: Swift.Error> {
    @Published public private(set) var isExecuting: Bool = false
    @Published public private(set) var isEnabled: Bool = false
    
    public let values: AnyPublisher<Output, Never>
    public let errors: AnyPublisher<Failure, Never>
    
    fileprivate let execute: (CombineAction, Input) -> AnyPublisher<Output, Failure>
    
    fileprivate var cancellables = Set<AnyCancellable>([])
    
    public convenience init<ExecutePublisher: Combine.Publisher>(
        execute: @escaping (Input) -> ExecutePublisher
    ) where ExecutePublisher.Output == Output, ExecutePublisher.Failure == Failure {
        self.init(enabledIf: Just(true), execute: execute)
    }
    
    public init<EnabledIfPublisher: Combine.Publisher, ExecutePublisher: Combine.Publisher>(
        enabledIf isEnabled: EnabledIfPublisher,
        execute: @escaping (Input) -> ExecutePublisher
    ) where
        EnabledIfPublisher.Output == Bool,
        EnabledIfPublisher.Failure == Never,
        ExecutePublisher.Output == Output,
        ExecutePublisher.Failure == Failure {
        let values = PassthroughSubject<Output, Never>()
        let errors = PassthroughSubject<Failure, Never>()
        
        self.values = values.eraseToAnyPublisher()
        self.errors = errors.eraseToAnyPublisher()
        
        let isExecutingLock = DispatchSemaphore(value: 1)
        self.execute = { action, input -> AnyPublisher<Output, Failure> in
            do {
                isExecutingLock.wait()
                defer { isExecutingLock.signal() }
                
                guard action.isEnabled == true, action.isExecuting == false
                else { return Empty().eraseToAnyPublisher() }
                
                action.isExecuting = true
            }
            return execute(input)
                .handleEvents(
                    receiveOutput: { value in
                        values.send(value)
                    },
                    receiveCompletion: { completion in
                        if case .failure(let error) = completion {
                            errors.send(error)
                        }
                        
                        isExecutingLock.wait()
                        defer { isExecutingLock.signal() }
                        action.isExecuting = false
                    },
                    receiveCancel: { [weak action] in
                        isExecutingLock.wait()
                        defer { isExecutingLock.signal() }
                        action?.isExecuting = false
                    }
                )
                .eraseToAnyPublisher()
        }
        
        Publishers
            .CombineLatest(
                isEnabled,
                self.$isExecuting
            )
            .map { $0 && !$1 }
            .sink { [weak self] value in self?.isEnabled = value }
            .store(in: &self.cancellables)
    }
        
    public func apply(_ input: Input) -> AnyPublisher<Output, Failure> {
        self.execute(self, input)
    }
}

extension CombineAction where Input == Void {
    public func apply() -> AnyPublisher<Output, Failure> {
        return self.apply(())
    }
}

extension Publisher {
    public func sinkUntilCompleted() {
        var cancellable: Cancellable?
        cancellable = sink(
            receiveCompletion: { _ in
                _ = cancellable
                cancellable = nil
            },
            receiveValue: { _ in }
        )
    }
}
