extension Request {
    final class BodyStream: BodyStreamWriter {
        typealias Handler = (BodyStreamResult, EventLoopPromise<Void>?) -> ()
        private(set) var isClosed: Bool
        private var handler: Handler?
        private var buffer: [(BodyStreamResult, EventLoopPromise<Void>?)]

        let eventLoop: EventLoop

        init(on eventLoop: EventLoop) {
            self.eventLoop = eventLoop
            self.isClosed = false
            self.buffer = []
        }

        func read(_ handler: @escaping Handler) {
            self.handler = handler
            for (result, promise) in self.buffer {
                handler(result, promise)
            }
            self.buffer = []
        }

        func write(_ chunk: BodyStreamResult, promise: EventLoopPromise<Void>?) {
            switch chunk {
            case .end, .error:
                self.isClosed = true
            case .buffer: break
            }
            
            if let handler = self.handler {
                handler(chunk, promise)
                // remove reference to handler
                switch chunk {
                case .end, .error:
                    self.handler = nil
                default: break
                }
            } else {
                self.buffer.append((chunk, promise))
            }
        }

        func consume(max: Int?, on eventLoop: EventLoop) -> EventLoopFuture<ByteBuffer> {
            let promise = eventLoop.makePromise(of: ByteBuffer.self)
            var data = ByteBufferAllocator().buffer(capacity: 0)
            self.read { chunk, next in
                switch chunk {
                case .buffer(var buffer):
                    if let max = max, data.readableBytes + buffer.readableBytes >= max {
                        promise.fail(Abort(.payloadTooLarge))
                    } else {
                        data.writeBuffer(&buffer)
                    }
                case .error(let error): promise.fail(error)
                case .end: promise.succeed(data)
                }
                next?.succeed(())
            }
            return promise.futureResult
        }

        deinit {
            assert(self.isClosed, "Request.BodyStream deinitialized before closing.")
        }
    }
}
