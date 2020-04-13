import XCTVapor

final class QueryTests: XCTestCase {
    func testQuery() throws {
        let app = Application()
        defer { app.shutdown() }

        let request = Request(application: app, on: app.eventLoopGroup.next())
        request.headers.contentType = .json
        request.url.path = "/foo"
        request.url.query = "hello=world"
        try XCTAssertEqual(request.query.get(String.self, at: "hello"), "world")
    }

    func testQueryAsArray() throws {
        let app = Application()
        defer { app.shutdown() }

        let request = Request(application: app, on: app.eventLoopGroup.next())
        request.headers.contentType = .json
        request.url.path = "/foo"
        request.url.query = "hello=world&hello[]=you"
        try XCTAssertEqual(request.query.get([String].self, at: "hello"), ["world", "you"])
        try XCTAssertEqual(request.query.get([String].self, at: "goodbye"), [])
    }

    // https://github.com/vapor/vapor/pull/2163
    func testWrappedSingleValueQueryDecoding() throws {
        let app = Application()
        defer { app.shutdown() }

        let request = Request(application: app, on: app.eventLoopGroup.next())
        request.headers.contentType = .json
        request.url.path = "/foo"
        request.url.query = ""

        // Think of property wrappers, or MongoKitten's ObjectId
        struct StringWrapper: Decodable {
            let string: String

            init(from decoder: Decoder) throws {
                let container = try decoder.singleValueContainer()
                string = try container.decode(String.self)
            }
        }

        XCTAssertThrowsError(try request.query.get(StringWrapper.self, at: "hello"))
    }

    func testNotCrashingArrayWithPercentEncoding() throws {
        let app = Application()
        defer { app.shutdown() }

        let request = Request(application: app, on: app.eventLoopGroup.next())
        request.headers.contentType = .json
        request.url.path = "/"
        request.url.query = "emailsToSearch%5B%5D=xyz"
        let parsed = try request.query.get([String].self, at: "emailsToSearch[]")
        XCTAssertEqual(parsed, ["xyz"])
    }

    func testQueryGet() throws {
        let app = Application()
        defer { app.shutdown() }

        var req: Request

        //
        req = Request(
            application: app,
            method: .GET,
            url: .init(string: "/path?foo=a"),
            on: app.eventLoopGroup.next()
        )

        XCTAssertEqual(try req.query.get(String.self, at: "foo"), "a")
        XCTAssertThrowsError(try req.query.get(Int.self, at: "foo")) { error in
            if case .typeMismatch(_, let context) = error as? DecodingError {
                XCTAssertEqual(context.debugDescription, "Data found at 'foo' was not Int")
            } else {
                XCTFail("Caught error \"\(error)\", but not the expected: \"DecodingError.typeMismatch\"")
            }
        }
        XCTAssertThrowsError(try req.query.get(String.self, at: "bar")) { error in
            if case .valueNotFound(_, let context) = error as? DecodingError {
                XCTAssertEqual(context.debugDescription, "No String was found at 'bar'")
            } else {
                XCTFail("Caught error \"\(error)\", but not the expected: \"DecodingError.valueNotFound\"")
            }
        }

        XCTAssertEqual(req.query[String.self, at: "foo"], "a")
        XCTAssertEqual(req.query[String.self, at: "bar"], nil)

        //
        req = Request(
            application: app,
            method: .GET,
            url: .init(string: "/path"),
            on: app.eventLoopGroup.next()
        )
        XCTAssertThrowsError(try req.query.get(Int.self, at: "foo")) { error in
            if let error = error as? DecodingError {
                XCTAssertEqual(error.status, .badRequest)
            } else {
                XCTFail("Caught error \"\(error)\"")
            }
        }
        XCTAssertEqual(req.query[String.self, at: "foo"], nil)
    }

    // https://github.com/vapor/vapor/issues/1537
    func testQueryStringRunning() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.routes.get("todos") { req in
            return "hi"
        }

        try app.testable().test(.GET, "/todos?a=b") { res in
            XCTAssertEqual(res.status, .ok)
            XCTAssertEqual(res.body.string, "hi")
        }
    }

    func testURLEncodedFormDecodeQuery() throws {
        struct User: Content {
            var name: String
            var age: Int
            var luckyNumbers: [Int]
        }

        let app = Application(.testing)
        defer { app.shutdown() }

        app.get("urlencodedform") { req -> HTTPStatus in
            debugPrint(req)
            let foo = try req.query.decode(User.self)
            XCTAssertEqual(foo.name, "Vapor")
            XCTAssertEqual(foo.age, 3)
            XCTAssertEqual(foo.luckyNumbers, [5, 7])
            return .ok
        }

        let data = "name=Vapor&age=3&luckyNumbers[]=5&luckyNumbers[]=7"
        try app.testable().test(.GET, "/urlencodedform?\(data)") { res in
            XCTAssertEqual(res.status.code, 200)
        }
    }

    func testCustomEncode() throws {
        let app = Application(.testing)
        defer { app.shutdown() }

        app.get("custom-encode") { req -> Response in
            let res = Response(status: .ok)
            let jsonEncoder = JSONEncoder()
            jsonEncoder.outputFormatting = .prettyPrinted
            try res.content.encode(["hello": "world"], using: jsonEncoder)
            return res
        }

        try app.testable().test(.GET, "/custom-encode") { res in
            XCTAssertEqual(res.body.string, """
            {
              "hello" : "world"
            }
            """)
        }
    }

    // https://github.com/vapor/vapor/issues/1609
    func testGH1609() throws {
        struct DecodeFail: Content {
            var here: String
            var missing: String
        }

        let app = Application(.testing)
        defer { app.shutdown() }

        app.post("decode-fail") { req -> String in
            _ = try req.content.decode(DecodeFail.self)
            return "ok"
        }

        var body = ByteBufferAllocator().buffer(capacity: 0)
        body.writeString(#"{"here":"hi"}"#)
        var headers = HTTPHeaders()
        headers.replaceOrAdd(name: .contentLength, value: body.readableBytes.description)
        headers.contentType = .json

        try app.testable().test(.POST, "/decode-fail", headers: headers, body: body) { res in
            XCTAssertEqual(res.status, .badRequest)
            XCTAssertContains(res.body.string, "missing")
        }
    }

    // https://github.com/vapor/vapor/issues/1687
    func testRequestQueryStringPercentEncoding() throws {
        let app = Application()
        defer { app.shutdown() }

        struct TestQueryStringContainer: Content {
            var name: String
        }
        let req = Request(application: app, on: app.eventLoopGroup.next())
        try req.query.encode(TestQueryStringContainer(name: "Vapor Test"))
        XCTAssertEqual(req.url.query, "name=Vapor%20Test")
    }
}
