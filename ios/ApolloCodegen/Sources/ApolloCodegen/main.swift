import Foundation
import ApolloCodegenLib

let srcRootUrl = FileFinder.findParentFolder() // ApolloCodegen folder
    .apollo.parentFolderURL() // Sources folder
    .apollo.parentFolderURL() // ApolloCodegen folder
    .apollo.parentFolderURL() // ios folder

let cliFolderUrl = srcRootUrl
    .apollo.childFolderURL(folderName: "ApolloCodegen")
    .apollo.childFolderURL(folderName: "ApolloCLI")

let targetFolderUrl = srcRootUrl
    .apollo.childFolderURL(folderName: "mina")
    .apollo.childFolderURL(folderName: "GraphQL")

let urlToSchemaFile = srcRootUrl
    .apollo.parentFolderURL() // mina folder
    .apollo.childFolderURL(folderName: "server")
    .appendingPathComponent("schema.json")

let outputFileUrl = targetFolderUrl
    .appendingPathComponent("API.swift")

// `schema.json` の位置がデフォルトの位置と違うので
// チュートリアルと異なり、細かい指定方法によるinitialize
// をする必要がある
let codegenOptions = ApolloCodegenOptions(
    outputFormat: .singleFile(atFileURL: outputFileUrl),
    urlToSchemaFile: urlToSchemaFile)

do {
    try ApolloCodegen.run(from: targetFolderUrl,
                          with: cliFolderUrl,
                          options: codegenOptions)
} catch {
    exit(1)
}
