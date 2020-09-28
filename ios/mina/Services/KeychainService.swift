//
//  KeychainItem.swift
//  mina
//
//  Created by 高橋篤樹 on 2020/09/23.
//  Copyright © 2020 高橋篤樹. All rights reserved.
//

import Foundation

struct KeychainService {
    
    // 基本的にはこのデフォルト値をそのまま使う (KeychainService().readCred()みたいな)
    // ただし、テスト用とデバッグ用でkeychainを分けるために、テスト時には
    // KeychainService(serviceName: "me.atsuki.minaTests").readCred()のように使う
    var serviceName: String = "me.atsuki.mina"
    
    enum KeychainError: Error {
        case unexpectedCredentialData
        case unhandledError(status: OSStatus)
    }
    
    func readCred() throws -> Credential? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
            kSecMatchLimit as String: kSecMatchLimitOne,
            kSecReturnAttributes as String: true, // usernameはattributeとして保存しているため、attributeもqueryする必要がある
            kSecReturnData as String: true,
        ]
        var item: CFTypeRef?
        let status = withUnsafeMutablePointer(to: &item) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // check the return status
        if status == errSecItemNotFound {
            return nil
        }
        guard status == errSecSuccess else { throw KeychainError.unhandledError(status: status)}
        
        // parse the result
        guard let existingItem = item as? [String: Any],
            let passwordData = existingItem[kSecValueData as String] as? Data,
            let password = String(data: passwordData, encoding: .utf8),
            let userId = existingItem[kSecAttrAccount as String] as? String
            else {
                throw KeychainError.unexpectedCredentialData
        }
        return Credential(userId: userId, password: password)
    }

    // GenericPasswordとしてkeychainに値を保存する
    func saveCred(cred: Credential) throws {
        let encodedPass = cred.password.data(using: .utf8)
        
        if try readCred() == nil {
            // 新規作成
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
                kSecAttrAccount as String: cred.userId,
                kSecValueData as String: encodedPass as Any,
            ]
            let status = SecItemAdd(query as CFDictionary, nil)
            if status != errSecSuccess {
                throw KeychainError.unhandledError(status: status)
            }
        } else {
            // 更新
            let query: [String: Any] = [
                kSecClass as String: kSecClassGenericPassword,
                kSecAttrService as String: serviceName,
            ]
            let updateQuery: [String: Any] = [
                kSecAttrAccount as String: cred.userId,
                kSecValueData as String: encodedPass as Any,
            ]
            let status = SecItemUpdate(query as CFDictionary, updateQuery as CFDictionary)
            if status != errSecSuccess {
                throw KeychainError.unhandledError(status: status)
            }
        }
    }
    
    func deleteCred() throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: serviceName,
        ]
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else { throw KeychainError.unhandledError(status: status)}
    }
}
