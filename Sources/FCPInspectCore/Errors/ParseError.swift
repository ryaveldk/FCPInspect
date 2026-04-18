import Foundation

public enum ParseError: Error, LocalizedError, Equatable {
    case unreadableFile(path: String, underlying: String)
    case missingInfoFile(bundle: String)
    case malformedXML(message: String)
    case missingRoot
    case wrongRoot(name: String)
    case missingAttribute(element: String, attribute: String, xpath: String)

    public var errorDescription: String? {
        switch self {
        case .unreadableFile(let path, let underlying):
            return "Cannot read file at '\(path)': \(underlying)"
        case .missingInfoFile(let bundle):
            return "Bundle '\(bundle)' does not contain an Info.fcpxml"
        case .malformedXML(let message):
            return "Malformed XML: \(message)"
        case .missingRoot:
            return "XML document has no root element"
        case .wrongRoot(let name):
            return "Expected <fcpxml> root element, got <\(name)>"
        case .missingAttribute(let element, let attribute, let xpath):
            return "Element <\(element)> at \(xpath) is missing required attribute '\(attribute)'"
        }
    }
}
