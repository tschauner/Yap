// UseCase.swift
// Yap

import Foundation

protocol UseCase {
    associatedtype Input
    associatedtype Output
    func execute(_ input: Input) async -> Output
}

protocol ThrowingUseCase {
    associatedtype Input
    associatedtype Output
    func execute(_ input: Input) async throws -> Output
}
