/* This Source Code Form is subject to the terms of the Mozilla Public
 * License, v. 2.0. If a copy of the MPL was not distributed with this
 * file, You can obtain one at http://mozilla.org/MPL/2.0/. */

import XCTest

// Note: this test is tested as part of the base test case, and thus is disabled here.

class HistoryTest: BaseTestCase {

    override func setUp() {
        super.setUp()
        dismissFirstRunUI()
    }

    override func tearDown() {
        app.terminate()
        super.tearDown()
    }

    func testHistoryItem() {
        let urlBarTextField = app.textFields["URLBar.urlText"]
        loadWebPage("http://localhost:6573/licenses.html")
        loadWebPage("bing.com")
        loadWebPage("https://www.google.com")

        waitforHittable(element: app.buttons["Back"])
        app.buttons["Back"].press(forDuration: 1)
        app.cells["http://localhost:6573/licenses.html"].tap()
        waitforNoExistence(element: app.menuItems["Back"])

        waitForWebPageLoad()
        guard let text = urlBarTextField.value as? String else {
            XCTFail()
            return
        }

        print("url: \(text)")
        XCTAssert(text == "localhost")
    }
}
