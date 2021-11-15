import Foundation

struct OceanSeaResponse: Decodable {
    let assets: [Asset]?
}

struct Asset: Decodable {
    enum CodingKeys: String, CodingKey {
        case id, name
        case imageUrl = "image_url"
        case thumbnailUrl = "image_thumbnail_url"
    }
    let id: Double
    let imageUrl: String?
    let thumbnailUrl: String?
    let name: String?
}
