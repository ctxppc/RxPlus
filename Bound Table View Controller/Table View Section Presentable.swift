// RxPlus © 2019 Constantino Tsarouhas

/// An item that can provide a table view section title and detail text.
///
/// Objects conforming to this protocol are part of an app's view model — adding conformance to this protocol is discouraged for types of data model objects since that would couple presentation behaviour to data. Instead, define a type that presents a given model object, even for model objects with a unique table view section presentation.
public protocol TableViewSectionPresentable {
	
	/// The section's title text, or `nil` if it doesn't have a title.
	var titleText: String? { get }
	
	/// The section's detail text, or `nil` if it doesn't have a detail text.
	var detailText: String? { get }
	
}
