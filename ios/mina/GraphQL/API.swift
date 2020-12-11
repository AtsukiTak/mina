// @generated
//  This file was automatically generated and should not be edited.

import Apollo
import Foundation

public final class AcceptPartnerRequestMutation: GraphQLMutation {
  /// The raw GraphQL definition of this operation.
  public let operationDefinition: String =
    """
    mutation AcceptPartnerRequest($requestId: UUID!) {
      acceptPartnerRequest(requestId: $requestId)
    }
    """

  public let operationName: String = "AcceptPartnerRequest"

  public var requestId: String

  public init(requestId: String) {
    self.requestId = requestId
  }

  public var variables: GraphQLMap? {
    return ["requestId": requestId]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes: [String] = ["Mutation"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("acceptPartnerRequest", arguments: ["requestId": GraphQLVariable("requestId")], type: .nonNull(.scalar(String.self))),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(acceptPartnerRequest: String) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "acceptPartnerRequest": acceptPartnerRequest])
    }

    /// パートナーリクエストを受理する
    public var acceptPartnerRequest: String {
      get {
        return resultMap["acceptPartnerRequest"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "acceptPartnerRequest")
      }
    }
  }
}

public final class GetMeQuery: GraphQLQuery {
  /// The raw GraphQL definition of this operation.
  public let operationDefinition: String =
    """
    query GetMe {
      me {
        __typename
        id
        name
        relationships {
          __typename
          id
          partner {
            __typename
            id
            name
          }
          callSchedules {
            __typename
            id
            time
            weekdays
          }
          nextCallTime
        }
        receivedPartnerRequests {
          __typename
          id
          from {
            __typename
            id
            name
          }
          to {
            __typename
            id
            name
          }
          isValid
        }
      }
    }
    """

  public let operationName: String = "GetMe"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes: [String] = ["Query"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("me", type: .nonNull(.object(Me.selections))),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(me: Me) {
      self.init(unsafeResultMap: ["__typename": "Query", "me": me.resultMap])
    }

    public var me: Me {
      get {
        return Me(unsafeResultMap: resultMap["me"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "me")
      }
    }

    public struct Me: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["Me"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .scalar(String.self)),
          GraphQLField("relationships", type: .nonNull(.list(.nonNull(.object(Relationship.selections))))),
          GraphQLField("receivedPartnerRequests", type: .nonNull(.list(.nonNull(.object(ReceivedPartnerRequest.selections))))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(id: String, name: String? = nil, relationships: [Relationship], receivedPartnerRequests: [ReceivedPartnerRequest]) {
        self.init(unsafeResultMap: ["__typename": "Me", "id": id, "name": name, "relationships": relationships.map { (value: Relationship) -> ResultMap in value.resultMap }, "receivedPartnerRequests": receivedPartnerRequests.map { (value: ReceivedPartnerRequest) -> ResultMap in value.resultMap }])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: String {
        get {
          return resultMap["id"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String? {
        get {
          return resultMap["name"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "name")
        }
      }

      public var relationships: [Relationship] {
        get {
          return (resultMap["relationships"] as! [ResultMap]).map { (value: ResultMap) -> Relationship in Relationship(unsafeResultMap: value) }
        }
        set {
          resultMap.updateValue(newValue.map { (value: Relationship) -> ResultMap in value.resultMap }, forKey: "relationships")
        }
      }

      public var receivedPartnerRequests: [ReceivedPartnerRequest] {
        get {
          return (resultMap["receivedPartnerRequests"] as! [ResultMap]).map { (value: ResultMap) -> ReceivedPartnerRequest in ReceivedPartnerRequest(unsafeResultMap: value) }
        }
        set {
          resultMap.updateValue(newValue.map { (value: ReceivedPartnerRequest) -> ResultMap in value.resultMap }, forKey: "receivedPartnerRequests")
        }
      }

      public struct Relationship: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["MyRelationship"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
            GraphQLField("partner", type: .nonNull(.object(Partner.selections))),
            GraphQLField("callSchedules", type: .nonNull(.list(.nonNull(.object(CallSchedule.selections))))),
            GraphQLField("nextCallTime", type: .scalar(String.self)),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: String, partner: Partner, callSchedules: [CallSchedule], nextCallTime: String? = nil) {
          self.init(unsafeResultMap: ["__typename": "MyRelationship", "id": id, "partner": partner.resultMap, "callSchedules": callSchedules.map { (value: CallSchedule) -> ResultMap in value.resultMap }, "nextCallTime": nextCallTime])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: String {
          get {
            return resultMap["id"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var partner: Partner {
          get {
            return Partner(unsafeResultMap: resultMap["partner"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "partner")
          }
        }

        public var callSchedules: [CallSchedule] {
          get {
            return (resultMap["callSchedules"] as! [ResultMap]).map { (value: ResultMap) -> CallSchedule in CallSchedule(unsafeResultMap: value) }
          }
          set {
            resultMap.updateValue(newValue.map { (value: CallSchedule) -> ResultMap in value.resultMap }, forKey: "callSchedules")
          }
        }

        public var nextCallTime: String? {
          get {
            return resultMap["nextCallTime"] as? String
          }
          set {
            resultMap.updateValue(newValue, forKey: "nextCallTime")
          }
        }

        public struct Partner: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["User"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("id", type: .nonNull(.scalar(String.self))),
              GraphQLField("name", type: .scalar(String.self)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(id: String, name: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "User", "id": id, "name": name])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var id: String {
            get {
              return resultMap["id"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "id")
            }
          }

          public var name: String? {
            get {
              return resultMap["name"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "name")
            }
          }
        }

        public struct CallSchedule: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["CallSchedule"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("id", type: .nonNull(.scalar(String.self))),
              GraphQLField("time", type: .nonNull(.scalar(String.self))),
              GraphQLField("weekdays", type: .nonNull(.scalar(String.self))),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(id: String, time: String, weekdays: String) {
            self.init(unsafeResultMap: ["__typename": "CallSchedule", "id": id, "time": time, "weekdays": weekdays])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var id: String {
            get {
              return resultMap["id"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "id")
            }
          }

          /// "21:45" のようなフォーマットの文字列
          public var time: String {
            get {
              return resultMap["time"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "time")
            }
          }

          /// "Mon,The,Thu,Fri" のようなコンマ区切りの文字列
          public var weekdays: String {
            get {
              return resultMap["weekdays"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "weekdays")
            }
          }
        }
      }

      public struct ReceivedPartnerRequest: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["PartnerRequest"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
            GraphQLField("from", type: .nonNull(.object(From.selections))),
            GraphQLField("to", type: .nonNull(.object(To.selections))),
            GraphQLField("isValid", type: .nonNull(.scalar(Bool.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: String, from: From, to: To, isValid: Bool) {
          self.init(unsafeResultMap: ["__typename": "PartnerRequest", "id": id, "from": from.resultMap, "to": to.resultMap, "isValid": isValid])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: String {
          get {
            return resultMap["id"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }

        public var from: From {
          get {
            return From(unsafeResultMap: resultMap["from"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "from")
          }
        }

        public var to: To {
          get {
            return To(unsafeResultMap: resultMap["to"]! as! ResultMap)
          }
          set {
            resultMap.updateValue(newValue.resultMap, forKey: "to")
          }
        }

        public var isValid: Bool {
          get {
            return resultMap["isValid"]! as! Bool
          }
          set {
            resultMap.updateValue(newValue, forKey: "isValid")
          }
        }

        public struct From: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["User"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("id", type: .nonNull(.scalar(String.self))),
              GraphQLField("name", type: .scalar(String.self)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(id: String, name: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "User", "id": id, "name": name])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var id: String {
            get {
              return resultMap["id"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "id")
            }
          }

          public var name: String? {
            get {
              return resultMap["name"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "name")
            }
          }
        }

        public struct To: GraphQLSelectionSet {
          public static let possibleTypes: [String] = ["User"]

          public static var selections: [GraphQLSelection] {
            return [
              GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
              GraphQLField("id", type: .nonNull(.scalar(String.self))),
              GraphQLField("name", type: .scalar(String.self)),
            ]
          }

          public private(set) var resultMap: ResultMap

          public init(unsafeResultMap: ResultMap) {
            self.resultMap = unsafeResultMap
          }

          public init(id: String, name: String? = nil) {
            self.init(unsafeResultMap: ["__typename": "User", "id": id, "name": name])
          }

          public var __typename: String {
            get {
              return resultMap["__typename"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "__typename")
            }
          }

          public var id: String {
            get {
              return resultMap["id"]! as! String
            }
            set {
              resultMap.updateValue(newValue, forKey: "id")
            }
          }

          public var name: String? {
            get {
              return resultMap["name"] as? String
            }
            set {
              resultMap.updateValue(newValue, forKey: "name")
            }
          }
        }
      }
    }
  }
}

public final class SearchPartnerQuery: GraphQLQuery {
  /// The raw GraphQL definition of this operation.
  public let operationDefinition: String =
    """
    query SearchPartner($userId: String!) {
      user(id: $userId) {
        __typename
        id
        name
      }
    }
    """

  public let operationName: String = "SearchPartner"

  public var userId: String

  public init(userId: String) {
    self.userId = userId
  }

  public var variables: GraphQLMap? {
    return ["userId": userId]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes: [String] = ["Query"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("user", arguments: ["id": GraphQLVariable("userId")], type: .nonNull(.object(User.selections))),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(user: User) {
      self.init(unsafeResultMap: ["__typename": "Query", "user": user.resultMap])
    }

    /// ユーザーをIDで検索する
    public var user: User {
      get {
        return User(unsafeResultMap: resultMap["user"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "user")
      }
    }

    public struct User: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["User"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("id", type: .nonNull(.scalar(String.self))),
          GraphQLField("name", type: .scalar(String.self)),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(id: String, name: String? = nil) {
        self.init(unsafeResultMap: ["__typename": "User", "id": id, "name": name])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var id: String {
        get {
          return resultMap["id"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "id")
        }
      }

      public var name: String? {
        get {
          return resultMap["name"] as? String
        }
        set {
          resultMap.updateValue(newValue, forKey: "name")
        }
      }
    }
  }
}

public final class SendPartnerRequestMutation: GraphQLMutation {
  /// The raw GraphQL definition of this operation.
  public let operationDefinition: String =
    """
    mutation SendPartnerRequest($toUserId: String!) {
      sendPartnerRequest(toUserId: $toUserId)
    }
    """

  public let operationName: String = "SendPartnerRequest"

  public var toUserId: String

  public init(toUserId: String) {
    self.toUserId = toUserId
  }

  public var variables: GraphQLMap? {
    return ["toUserId": toUserId]
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes: [String] = ["Mutation"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("sendPartnerRequest", arguments: ["toUserId": GraphQLVariable("toUserId")], type: .nonNull(.scalar(String.self))),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(sendPartnerRequest: String) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "sendPartnerRequest": sendPartnerRequest])
    }

    /// パートナーリクエストを送信する
    public var sendPartnerRequest: String {
      get {
        return resultMap["sendPartnerRequest"]! as! String
      }
      set {
        resultMap.updateValue(newValue, forKey: "sendPartnerRequest")
      }
    }
  }
}

public final class SignupAsAnonymousMutation: GraphQLMutation {
  /// The raw GraphQL definition of this operation.
  public let operationDefinition: String =
    """
    mutation SignupAsAnonymous {
      signupAsAnonymous {
        __typename
        user {
          __typename
          id
        }
        secret
      }
    }
    """

  public let operationName: String = "SignupAsAnonymous"

  public init() {
  }

  public struct Data: GraphQLSelectionSet {
    public static let possibleTypes: [String] = ["Mutation"]

    public static var selections: [GraphQLSelection] {
      return [
        GraphQLField("signupAsAnonymous", type: .nonNull(.object(SignupAsAnonymou.selections))),
      ]
    }

    public private(set) var resultMap: ResultMap

    public init(unsafeResultMap: ResultMap) {
      self.resultMap = unsafeResultMap
    }

    public init(signupAsAnonymous: SignupAsAnonymou) {
      self.init(unsafeResultMap: ["__typename": "Mutation", "signupAsAnonymous": signupAsAnonymous.resultMap])
    }

    /// anonymousとして登録する
    public var signupAsAnonymous: SignupAsAnonymou {
      get {
        return SignupAsAnonymou(unsafeResultMap: resultMap["signupAsAnonymous"]! as! ResultMap)
      }
      set {
        resultMap.updateValue(newValue.resultMap, forKey: "signupAsAnonymous")
      }
    }

    public struct SignupAsAnonymou: GraphQLSelectionSet {
      public static let possibleTypes: [String] = ["UserAndSecret"]

      public static var selections: [GraphQLSelection] {
        return [
          GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
          GraphQLField("user", type: .nonNull(.object(User.selections))),
          GraphQLField("secret", type: .nonNull(.scalar(String.self))),
        ]
      }

      public private(set) var resultMap: ResultMap

      public init(unsafeResultMap: ResultMap) {
        self.resultMap = unsafeResultMap
      }

      public init(user: User, secret: String) {
        self.init(unsafeResultMap: ["__typename": "UserAndSecret", "user": user.resultMap, "secret": secret])
      }

      public var __typename: String {
        get {
          return resultMap["__typename"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "__typename")
        }
      }

      public var user: User {
        get {
          return User(unsafeResultMap: resultMap["user"]! as! ResultMap)
        }
        set {
          resultMap.updateValue(newValue.resultMap, forKey: "user")
        }
      }

      public var secret: String {
        get {
          return resultMap["secret"]! as! String
        }
        set {
          resultMap.updateValue(newValue, forKey: "secret")
        }
      }

      public struct User: GraphQLSelectionSet {
        public static let possibleTypes: [String] = ["User"]

        public static var selections: [GraphQLSelection] {
          return [
            GraphQLField("__typename", type: .nonNull(.scalar(String.self))),
            GraphQLField("id", type: .nonNull(.scalar(String.self))),
          ]
        }

        public private(set) var resultMap: ResultMap

        public init(unsafeResultMap: ResultMap) {
          self.resultMap = unsafeResultMap
        }

        public init(id: String) {
          self.init(unsafeResultMap: ["__typename": "User", "id": id])
        }

        public var __typename: String {
          get {
            return resultMap["__typename"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "__typename")
          }
        }

        public var id: String {
          get {
            return resultMap["id"]! as! String
          }
          set {
            resultMap.updateValue(newValue, forKey: "id")
          }
        }
      }
    }
  }
}
