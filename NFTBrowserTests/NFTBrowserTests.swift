import XCTest
@testable import NFTBrowser

class NFTBrowserTests: XCTestCase {
    
    func testParser() {
        let file = Bundle(for: type(of: self)).url(forResource: "opensea", withExtension: "json")
        let response = try! JSONDecoder().decode(OpenSeaResponse.self, from: Data(contentsOf: file!.absoluteURL))
        XCTAssertNotNil(response)
        XCTAssertNotNil(response.assets)
        XCTAssertFalse(response.assets!.isEmpty)
        let asset = response.assets?.first
        XCTAssertEqual(asset?.imageUrl, "https://lh3.googleusercontent.com/K9zvzFCnnJ63aJbIE7ZZoQVvTls3mMXhoOSjcyII_hJ9VBYbnIy13own05RjRO_KpsPtbY5KrWQg6GqUSLKnd0cJDyR1SgeXmeOF")
        XCTAssertEqual(asset?.id, 100781426)
        XCTAssertEqual(asset?.thumbnailUrl, "https://lh3.googleusercontent.com/K9zvzFCnnJ63aJbIE7ZZoQVvTls3mMXhoOSjcyII_hJ9VBYbnIy13own05RjRO_KpsPtbY5KrWQg6GqUSLKnd0cJDyR1SgeXmeOF=s128")
    }

}
