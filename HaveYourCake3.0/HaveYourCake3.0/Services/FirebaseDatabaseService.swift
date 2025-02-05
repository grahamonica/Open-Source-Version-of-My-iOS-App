//
//  FirebaseDatabaseService.swift
//  HaveYourCake3.0
//
//  Created by Monica Graham on 1/20/25.
//
// Trying to move a lot of stuff out of HomeViewModel becayse it is getting wayy too crowded

import Foundation
import FirebaseAuth
import FirebaseFirestore

class FirebaseDatabaseService {
    private let db = Firestore.firestore()
    private var userID: String? {
        return Auth.auth().currentUser?.uid
    }

    // MARK: - Load Lists
    func loadLists(completion: @escaping (Result<([ListModel], [ListModel]), Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(FirebaseError.unauthenticated))
            return
        }

        db.collection("users").document(userID).collection("lists").getDocuments { snapshot, error in
            if let error = error {
                completion(.failure(error))
                return
            }

            guard let documents = snapshot?.documents else {
                completion(.success(([], []))) // No data
                return
            }

            do {
                let allLists = try documents.compactMap { try $0.data(as: ListModel.self) }
                let activeLists = allLists.filter { !$0.isDeleted }
                let deletedLists = allLists.filter { $0.isDeleted }
                completion(.success((activeLists, deletedLists)))
            } catch {
                completion(.failure(error))
            }
        }
    }

    // MARK: - Add List
    func addList(_ list: ListModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(FirebaseError.unauthenticated))
            return
        }

        do {
            try db.collection("users").document(userID).collection("lists").document(list.id.uuidString).setData(from: list) {
                error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Update List
    func updateList(_ list: ListModel, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(FirebaseError.unauthenticated))
            return
        }

        do {
            try db.collection("users").document(userID).collection("lists").document(list.id.uuidString).setData(from: list) {
                error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } catch {
            completion(.failure(error))
        }
    }

    // MARK: - Delete List
    func deleteList(_ list: ListModel, permanently: Bool, completion: @escaping (Result<Void, Error>) -> Void) {
        guard let userID = userID else {
            completion(.failure(FirebaseError.unauthenticated))
            return
        }

        if permanently {
            db.collection("users").document(userID).collection("lists").document(list.id.uuidString).delete { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        } else {
            var softDeletedList = list
            softDeletedList.isDeleted = true
            updateList(softDeletedList, completion: completion)
        }
    }

    // MARK: - Restore List
    func restoreList(_ list: ListModel, completion: @escaping (Result<Void, Error>) -> Void) {
        var restoredList = list
        restoredList.isDeleted = false
        updateList(restoredList, completion: completion)
    }

    // MARK: - Error Handling
    enum FirebaseError: Error {
        case unauthenticated
    }
}
