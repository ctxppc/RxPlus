// RxPlus © 2019 Constantino Tsarouhas

import UIKit

/// An item that can provide a table view section title and detail text.
///
/// Objects conforming to this protocol are part of an app's view model — adding conformance to this protocol is discouraged for types of data model objects since that would couple presentation behaviour to data. Instead, define a type that presents a given model object, even for model objects with a unique table view section presentation.
public protocol TableViewSectionViewPresentable {
	
	/// Returns a header view for the section.
	///
	/// - Parameter sectionIndex: The index of the section.
	///
	/// - Returns: A header view or `nil` if the section doesn't have a header.
	func headerView(for sectionIndex: Int) -> UIView?
	
	/// Returns the estimated height of the footer view in points, or `0` if the section doesn't have a footer.
	func estimatedHeaderViewHeight(for sectionIndex: Int) -> CGFloat
	
	/// Returns the height of the header view in points, or `0` if the section doesn't have a header.
	func headerViewHeight(for sectionIndex: Int) -> CGFloat
	
	/// Returns a footer view for the section.
	///
	/// - Parameter sectionIndex: The index of the section.
	///
	/// - Returns: A footer view or `nil` if the section doesn't have a footer.
	func footerView(for sectionIndex: Int) -> UIView?
	
	/// Returns the estimated height of the footer view in points, or `0` if the section doesn't have a footer.
	func estimatedFooterViewHeight(for sectionIndex: Int) -> CGFloat
	
	/// Returns the height of the footer view in points, or `0` if the section doesn't have a footer.
	func footerViewHeight(for sectionIndex: Int) -> CGFloat
	
}
