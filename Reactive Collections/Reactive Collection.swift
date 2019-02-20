// RxPlus © 2019 Constantino Tsarouhas

import RxSwift

/// A collection with reference semantics that can be observed for changes.
///
/// Reactive collections can be used to continuously monitor for and react to changes to a mutable collection of elements. Reactive collections act like lazy collections but whose contents can change in response to internal or external sources. When a reactive collection changes, it emits a `CollectionDifference` value describing the difference between the previous and new state. A collection never emits errors and emits a completion event before it's deallocated.
///
/// Reactive collections are not thread-safe. Unless the concrete type allows otherwise, a reactive collection must observe and emit changes and be accessed on the same thread.
///
/// `ReactiveCollection` follows a model similar to `LazyCollectionProtocol`. To implement an operation like `map` or `filter` with reactive semantics, define a class that conforms to this protocol and `ObserverType`, then add a method in an extension of `ReactiveCollection`. Collection operations from `Collection` without reactive counterpart are simply implemented as nonreactive operations, with a result that doesn't conform to `ReactiveCollection`. To implement a reactive collection that changes itself (e.g., in response to external changes), define a class that conforms to this protocol but not `ObserverType`.
///
/// The `ReactiveCollection` doesn't declare any members beyond those declared by `Collection` and `ObservableType`. Conformance to this protocol simply ensures that the resulting collection always emits difference values whenever it changes.
public protocol ReactiveCollection : class, Collection, ObservableType where E == CollectionDifference<Element> {}
