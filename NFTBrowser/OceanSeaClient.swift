import Foundation

enum OceanSeaError: Error, CustomStringConvertible {
    case networkError(Error)
    case responseError
    var description: String {
        switch self {
        case .networkError(let error):
            return "Network error \(error.localizedDescription)"
        case .responseError:
            return "Response error"            
        }
    }
}

struct NextToken: CustomStringConvertible {
    let offset: Int
    
    // can't be created outside of this scope
    fileprivate init(offset: Int) {
        self.offset = offset
    }
    var description: String { return "Offset \(offset)"}
}

enum OceanSeaResult {
    case assets([Asset], NextToken)
    case empty
}

class OceanSeaClient {
    let resultsLimit = 20
    typealias CompletionHandler = ((Result<OceanSeaResult, OceanSeaError>) -> Void)
    let ocenSeaUrl = "https://api.opensea.io/api/v1/assets?order_direction=desc&offset=0&limit=20"
    
    func fetchAssets(_ completion: @escaping CompletionHandler) {
        let task = URLSession.shared.dataTask(with: URL(string: ocenSeaUrl)!) { data, _, networkError in
            if let networkError = networkError {
                DispatchQueue.main.async {
                    completion(.failure(.networkError(networkError)))
                }
                return
            }
            guard let data = data else {
                DispatchQueue.main.async {
                    completion(.failure(.responseError))
                }
                return
            }
            do {
                if let responseString = String(data: data, encoding: .utf8) {
                    debugPrint("Server response: \(responseString)")
                }
                let response = try JSONDecoder().decode(OceanSeaResponse.self, from: data)
                DispatchQueue.main.async {
                    if let assets = response.assets, !assets.isEmpty {
                        completion(.success(.assets(assets, NextToken(offset: assets.count))))
                    } else {
                        completion(.success(.empty))
                    }
                }
            } catch {
                debugPrint("\(error)")
                DispatchQueue.main.async {
                    completion(.failure(.responseError))
                }
            }
        }
        task.resume()
    }
    func fetchMore(_ nextToken: NextToken, completion: @escaping CompletionHandler) {
        
    }
}
