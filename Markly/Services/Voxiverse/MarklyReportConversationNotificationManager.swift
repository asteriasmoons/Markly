//
//  MarklyReportConversationNotificationManager.swift
//  Markly
//

import CloudKit
import Foundation
import UIKit
import UserNotifications

enum MarklyReportConversationNotificationManager {
    static let conversationNotificationOpened = Notification.Name("MarklyReportConversationNotificationOpened")
    static let conversationDataDidChange = Notification.Name("MarklyReportConversationDataDidChange")

    static func registerSharedConversationNotifications(database: CKDatabase, zoneID: CKRecordZone.ID) async throws {
        await MainActor.run {
            UIApplication.shared.registerForRemoteNotifications()
        }

        let subscriptionID = "markly-report-conversations-\(zoneID.ownerName)-\(zoneID.zoneName)"
        let subscription: CKRecordZoneSubscription
        if let existing = try? await database.subscriptions(for: [subscriptionID]),
           let result = existing[subscriptionID],
           let savedSubscription = try? result.get() as? CKRecordZoneSubscription {
            subscription = savedSubscription
        } else {
            subscription = CKRecordZoneSubscription(zoneID: zoneID, subscriptionID: subscriptionID)
        }

        // CloudKit subscriptions are scoped to the shared container/account,
        // not exclusively to Markly. Keep the push silent so another app using
        // this container can never display Markly's conversation alert.
        let info = CKSubscription.NotificationInfo()
        info.shouldSendContentAvailable = true
        subscription.notificationInfo = info
        _ = try await database.modifySubscriptions(saving: [subscription], deleting: [])
    }

    static func notifyInvitationDiscovered(reportID: String, reportTitle: String) async {
        let notificationKey = "markly.reportConversation.invitationNotified.\(reportID)"
        guard !UserDefaults.standard.bool(forKey: notificationKey) else { return }

        let granted = await requestAuthorizationIfNeeded()
        guard granted else { return }

        let content = UNMutableNotificationContent()
        content.title = "Voxiverse"
        content.body = "Voxiverse invited you to a private conversation about your report."
        content.userInfo = [
            "kind": "reportConversationInvitation",
            "reportID": reportID,
            "reportTitle": reportTitle
        ]
        content.sound = .default

        let request = UNNotificationRequest(
            identifier: "markly-report-conversation-invite-\(reportID)",
            content: content,
            trigger: nil
        )
        do {
            try await UNUserNotificationCenter.current().add(request)
            UserDefaults.standard.set(true, forKey: notificationKey)
        } catch {
            // Keep the key unset so a temporary scheduling failure can retry.
        }
    }

    private static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        switch settings.authorizationStatus {
        case .authorized, .provisional, .ephemeral:
            await MainActor.run {
                UIApplication.shared.registerForRemoteNotifications()
            }
            return true
        case .notDetermined:
            let granted = (try? await center.requestAuthorization(options: [.alert, .badge, .sound])) ?? false
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            return granted
        case .denied:
            return false
        @unknown default:
            return false
        }
    }
}

final class MarklyNotificationDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        UNUserNotificationCenter.current().delegate = self
        return true
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        [.banner, .sound, .badge]
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse
    ) async {
        let userInfo = response.notification.request.content.userInfo
        guard let reportID = userInfo["reportID"] as? String, !reportID.isEmpty else { return }
        await MainActor.run {
            NotificationCenter.default.post(
                name: MarklyReportConversationNotificationManager.conversationNotificationOpened,
                object: reportID
            )
        }
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        guard let notification = CKNotification(fromRemoteNotificationDictionary: userInfo),
              notification.subscriptionID?.hasPrefix("markly-report-conversations-") == true else {
            completionHandler(.noData)
            return
        }

        NotificationCenter.default.post(
            name: MarklyReportConversationNotificationManager.conversationDataDidChange,
            object: nil
        )
        completionHandler(.newData)
    }
}
