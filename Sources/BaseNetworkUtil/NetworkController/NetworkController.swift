import Foundation
import Combine

public class NetworkController: NetworkControllerProtocol {
	public let source: [String]
	public let identificationInfo: IdentificationInfo
	
	public var delegate: NetworkControllerDelegate? = nil
	public let logger = Logger()
	
	public init (
		source: [String] = [String(describing: NetworkController.self)],
		label: String? = nil,
		file: String = #fileID,
		line: Int = #line
	) {
		self.source = source
		self.identificationInfo = IdentificationInfo(Info.moduleName, type: String(describing: Self.self), file: file, line: line, label: label)
	}
}

extension NetworkController {
	public func send <RD: RequestDelegate> (_ requestDelegate: RD, label: String? = nil) -> AnyPublisher<RD.ContentType, NetworkController.Error> {
		let requestInfo = RequestInfo(controllersIdentificationInfo: [], source: [], requestUuid: UUID(), sendingLabel: label)
		return _send(requestDelegate, requestInfo, label)
	}
	
	func _send <RD: RequestDelegate> (_ requestDelegate: RD, _ requestInfo: RequestInfo, source: [String] = [], _ label: String?) -> AnyPublisher<RD.ContentType, NetworkController.Error> {
		
		let requestInfo = requestInfo
			.add(identificationInfo)
			.add(source)
		
		let requestPublisher = Just(requestDelegate)
			.handleEvents(receiveOutput: { requestDelegate in self.logger.onDelegate.send(.init(requestInfo, requestDelegate)) })
			.tryMap { (requestDelegate: RD) -> RD.RequestType in
				try requestDelegate.request(requestInfo)
			}
			.handleEvents(receiveOutput: { (request: RD.RequestType) in self.logger.onUnmodifiedRequest.send(.init(requestInfo, request)) })
			.tryMap { (request: RD.RequestType) -> RD.RequestType in
				try self.delegate?.request(request, requestInfo) ?? request
			}
			.handleEvents(receiveOutput: { request in self.logger.onRequest.send(.init(requestInfo, request)) })
			
			
			
			.tryMap { (request: RD.RequestType) -> (URLSession, URLRequest) in
				try (requestDelegate.urlSession(request, requestInfo), requestDelegate.urlRequest(request, requestInfo))
			}
			.handleEvents(receiveOutput: { (urlSession: URLSession, urlRequest: URLRequest) in self.logger.onUnmodifiedUrlRequest.send(.init(requestInfo, (urlSession, urlRequest))) })
			.tryMap { (urlSession: URLSession, urlRequest: URLRequest) -> (URLSession, URLRequest) in
				let urlSession = try self.delegate?.urlSession(urlSession, requestInfo) ?? urlSession
				let urlRequest = try self.delegate?.urlRequest(urlRequest, requestInfo) ?? urlRequest
				return (urlSession, urlRequest)
			}
			.handleEvents(receiveOutput: { (urlSession: URLSession, urlRequest: URLRequest) in self.logger.onUrlRequest.send(.init(requestInfo, (urlSession, urlRequest))) })
			
			.mapError { Error(.preprocessingFailure($0)) }
			
			
			
			.flatMap { (urlSession: URLSession, urlRequest: URLRequest) -> AnyPublisher<(data: Data, response: URLResponse), NetworkController.Error> in
				return urlSession.dataTaskPublisher(for: urlRequest)
					.mapError {	Error(.networkFailure(urlSession, urlRequest, $0)) }
					.eraseToAnyPublisher()
			}
			
			
			
			.handleEvents(receiveOutput: { (data: Data, urlResponse: URLResponse) in self.logger.onUrlResponse.send(.init(requestInfo, (data, urlResponse))) })
			.tryMap { (data: Data, urlResponse: URLResponse) -> (Data, URLResponse) in
				try (self.delegate?.data(data, requestInfo) ?? data, self.delegate?.urlResponse(urlResponse, requestInfo) ?? urlResponse)
			}
			.handleEvents(receiveOutput: { (data: Data, urlResponse: URLResponse) in self.logger.onModifiedUrlResponse.send(.init(requestInfo, (data, urlResponse))) })
			
			
			
			.tryMap { (data: Data, urlResponse: URLResponse) -> RD.ResponseType in
				try requestDelegate.response(data, urlResponse, requestInfo)
			}
			.handleEvents(receiveOutput: { (response: RD.ResponseType) in self.logger.onResponse.send(.init(requestInfo, response)) })
			.tryMap { (response: RD.ResponseType) -> RD.ResponseType in
				try self.delegate?.response(response, requestInfo) ?? response
			}
			.handleEvents(receiveOutput: { (response: RD.ResponseType) in self.logger.onModifiedResponse.send(.init(requestInfo, response)) })
			
			
			
			.tryMap { (response: RD.ResponseType) -> RD.ContentType in
				try requestDelegate.content(response, requestInfo)
			}
			.handleEvents(receiveOutput: { (content: RD.ContentType) in self.logger.onContent.send(.init(requestInfo, content)) })
			.tryMap { (content: RD.ContentType) -> RD.ContentType in
				try self.delegate?.content(content, requestInfo) ?? content
			}
			.handleEvents(receiveOutput: { (content: RD.ContentType) in self.logger.onModifiedContent.send(.init(requestInfo, content)) })
			
			
			
			.mapError {	Error(.postprocessingFailure($0)) }
			.handleEvents(
				receiveCompletion: { completion in
					if case .failure(let error) = completion {
						requestDelegate.error(error, requestInfo)
						self.delegate?.error(error, requestInfo)
						self.logger.onError.send(.init(requestInfo, error))
					}
				}
			)
		
		return requestPublisher.eraseToAnyPublisher()
	}
}

extension NetworkController {
	@discardableResult
	public func delegate (_ delegate: NetworkControllerDelegate) -> NetworkController {
		self.delegate = delegate
		return self
	}
	
	@discardableResult
	public func logging (_ logging: (Logger) -> ()) -> NetworkController {
		logging(logger)
		return self
	}
	
	@discardableResult
	public func logHandler (_ logHandler: ControllerLogHandler) -> NetworkController {
		logger
			.onUrlRequest { logRecord in
				logHandler.log(.init(logRecord.requestInfo, .request(logRecord.details.urlSession, logRecord.details.urlRequest)))
			}
			.onUrlResponse { logRecord in
				logHandler.log(.init(logRecord.requestInfo, .response(logRecord.details.data, logRecord.details.urlResponse)))
			}
			.onError { logRecord in
				logHandler.log(.init(logRecord.requestInfo, .error(logRecord.details)))
			}
		
		return self
	}
}
