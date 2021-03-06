import XCTest
import Combine
@testable import NetworkUtil

public struct Model: Codable {
	public static let dateFormatter: DateFormatter = {
		let dateFormatter = DateFormatter()
		dateFormatter.dateFormat = "yyyy.MM.dd HH:mm:ss.SSSS"
		return dateFormatter
	}()
	
	public let date: String
	public let timestamp: Double
	public let info: [String: String]?
	public let processId: String
	
	public init (date: Date, info: [String: String]?, processId: String) {
		self.date = Self.dateFormatter.string(from: date)
		self.timestamp = date.timeIntervalSince1970
		self.info = info
		self.processId = processId
	}
}

final class NetworkFlowUtilTests: XCTestCase {
	var cancellables = Set<AnyCancellable>()
	
//	func test () {
//		let controller = Serial(
//			StandardNetworkController()
//				.logging { logger in
//					logger
//						.onDelegate { print("Request – \($0.requestInfo)") }
//						.onContent { print("Response  – \($0.requestInfo)") }
//				}
//				.serial()
//		)
//		
//		let url = URL(string: "http://localhost/echo/")!
//		let array = Array(1...10)
//		
//		for item in array {
//			let request = URLRequest(url: url.appendingPathComponent(String(item)))
////			print("Request  – \(item) – \(Model.dateFormatter.string(from: Date()))")
//			controller.send(request, label: "\(item)")
//				.map { $0.data }
//				.decode(type: [String: Model].self, decoder: JSONDecoder())
//				.sink(
//					receiveCompletion: { completion in
//						if case let .failure(error) = completion {
//							print(error)
//						}
//					},
//					receiveValue: { response in
////						print("Response – \(item) – \(response["echo"]!.date)")
//					}
//				)
//				.store(in: &cancellables)
//		}
//		
//		let g = DispatchGroup()
//		g.enter()
//		_ = g.wait(wallTimeout: .now() + 2)
//	}
	
	func test2 () {
		let controller = Serial(StandardNetworkController())
		
		let request = URLRequest(url: URL(string: "http://localhost")!)
		
		print("Request")
		controller.send(request)
			.handleEvents(receiveOutput: { _ in print("Response") })
			.sink(receiveCompletion: { _ in }, receiveValue: { _ in print("Response 1") })
			.store(in: &cancellables)
		
		let g = DispatchGroup()
		g.enter()
		_ = g.wait(wallTimeout: .now() + 2)
	}
	
	func test3 () {
		let controller = Serial(StandardNetworkController())
		
		let request = URLRequest(url: URL(string: "http://localhost")!)
		
		print("Request")
		controller.send(request)
			.handleEvents(receiveOutput: { _ in print("Response") })
			.sink(receiveCompletion: { _ in }, receiveValue: { _ in print("Response 1") })
			.store(in: &cancellables)
		
		let g = DispatchGroup()
		g.enter()
		_ = g.wait(wallTimeout: .now() + 2)
	}
	
	func test4 () {
		_ = PassthroughSubject<String, Never>()
		
		
		let g = DispatchGroup()
		g.enter()
		_ = g.wait(wallTimeout: .now() + 2)
	}
	
	func test6 () {
		let c = StandardNetworkController()
		c
			.logging { record in
				
			}
			.loggerSetup { logger in
				
			}
	}
    
    func test7 () {
        StandardNativeNetworkController().send(URL(string: "")!) { data, urlResponse in }
        StandardNativeNetworkController().send(URL(string: "")!) { data, urlResponse in }

        
        
    }
}
