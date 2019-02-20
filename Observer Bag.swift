// RxPlus © 2019 Constantino Tsarouhas

import RxSwift

/// A container of subscribed observers.
///
/// Observers can subscribe more than once in which case events will be emitted to them multiple times.
internal final class ObserverBag<E> {
	
	private var observers: Set<Observer<E>> = []
	
	func subscribe<O : ObserverType>(_ observer: O) -> Disposable where O.E == E {
		let observer = Observer(observer)
		observers.insert(observer)
		return Disposables.create { [weak self] in
			self?.observers.remove(observer)
		}
	}
	
	var isEmpty: Bool {
		return observers.isEmpty
	}
	
	func emit(_ event: Event<E>) {
		for observer in observers {
			observer.on(event)
		}
	}
	
	func emit(_ value: E) {
		emit(.next(value))
	}
	
}

/// A type-erased observer with reference semantics.
private final class Observer<E> : ObserverType, Hashable {
	
	init<Observer : ObserverType>(_ base: Observer) where Observer.E == E {
		handler = base.on
	}
	
	private let handler: (Event<E>) -> ()
	
	func on(_ event: Event<E>) {
		handler(event)
	}
	
	func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
	
}

extension Observer {
	static func == <E> (firstObserver: Observer<E>, otherObserver: Observer<E>) -> Bool {
		return firstObserver === otherObserver
	}
}
