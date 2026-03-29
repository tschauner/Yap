//
//  Localizable.swift
//  Yap
//
//  Created by Philipp Tschauner on 14.03.26.
//

import Foundation

enum L10n {
    
    // MARK: - Common
    enum Common {
        static let cancel = "common_cancel".localized
        static let done = "common_done".localized
        static let off = "common_off".localized
        static let ok = "common_ok".localized
        static let error = "common_error".localized
    }
    
    // MARK: - Legal
    enum Legal {
        static let privacyPolicy = "legal_privacy_policy".localized
        static let termsOfUse = "legal_terms_of_use".localized
    }
    
    // MARK: - Onboarding
    enum Onboarding {
        static let headline = "onboarding_start_headline".localized
        static let subline = "onboarding_start_subline".localized
        static let agentsHeadline = "onboarding_agents_headline".localized
        static let agentsSubline = "onboarding_agents_subline".localized
        static let deadlineHeadline = "onboarding_deadline_headline".localized
        static let deadlineSubline = "onboarding_deadline_subline".localized
        static let start = "onboarding_deadline_start".localized
        static let deadline = "onboarding_deadline_deadline".localized
        static let notificationsEnabled = "onboarding_notifications_enabled".localized
        static let notificationsDisabled = "onboarding_notifications_disabled".localized
        static let notificationsReady = "onboarding_notifications_ready".localized
        static let notificationsAgentFallback = "onboarding_notifications_agent_fallback".localized
        static let notificationsDisabledSubline = "onboarding_notifications_disabled_subline".localized
        static let notificationsDenied = "onboarding_notifications_denied".localized
        static let notificationsDeniedSubline = "onboarding_notifications_denied_subline".localized
        static let continueAnyway = "onboarding_button_continue_anyway".localized
        static let letsGo = "onboarding_button_lets_go".localized
        static let allowNotifications = "onboarding_button_allow_notifications".localized
        static let next = "onboarding_button_next".localized
        static let nameHeadline = "onboarding_name_headline".localized
        static let nameSubline = "onboarding_name_subline".localized
        static let namePlaceholder = "onboarding_name_placeholder".localized
        static let maybeLater = "onboarding_paywall_maybe_later".localized
        static func goProPrice(_ price: String) -> String { "onboarding_paywall_go_pro_price".localized(with: price) }
        static let lifetimeSubline = "onboarding_paywall_lifetime_subline".localized
        static let goPro = "onboarding_paywall_go_pro".localized
    }
    
    // MARK: - Mission
    enum Mission {
        static let holdToComplete = "mission_hold_to_complete".localized
        static let giveUp = "mission_give_up".localized
        static let setAnother = "mission_set_another".localized
        static let extendTitle = "mission_extend_title".localized
        static let extendMessage = "mission_extend_message".localized
        static let extend2h = "mission_extend_2h".localized
        static let extend24h = "mission_extend_24h".localized
        static let selectionHeadline = "mission_selection_headline".localized
        static let agentsLabel = "mission_selection_agents".localized
        static let showMore = "mission_selection_show_more".localized
        static let notificationsDisabledTitle = "mission_notifications_disabled_title".localized
        static let notificationsDisabledSubline = "mission_notifications_disabled_subline".localized
        static let openSettings = "mission_open_settings".localized
        static let achievements = "mission_toolbar_achievements".localized
        static let left = "mission_time_left".localized
        static func shareMessage(_ url: String) -> String { "mission_share_message".localized(with: url) }
        static let creationFailed = "mission_creation_failed".localized
        static func messagesIgnored(_ count: Int) -> String { "mission_messages_ignored".localized(with: count) }
        static func messagesScheduled(_ count: Int) -> String { "mission_messages_scheduled".localized(with: count) }
    }
    
    // MARK: - Input
    enum Input {
        static let placeholder = "input_mission_placeholder".localized
        static func deadlineLabel(_ time: String) -> String { "input_deadline_label".localized(with: time) }
        static let agentPlaceholder = "input_agent_placeholder".localized
        static let deadlinePickerTitle = "input_deadline_picker_title".localized
    }
    
    // MARK: - Quiet Hours
    enum QuietHours {
        static let title = "quiet_hours_title".localized
        static let enabled = "quiet_hours_enabled".localized
        static let footer = "quiet_hours_footer".localized
        static let from = "quiet_hours_from".localized
        static let until = "quiet_hours_until".localized
        static let alertTitle = "quiet_hours_alert_title".localized
        static func alertMessage(_ range: String) -> String { "quiet_hours_alert_message".localized(with: range) }
        static let alertStart = "quiet_hours_alert_start".localized
        static let alertChange = "quiet_hours_alert_change".localized
    }
    
    // MARK: - Agents
    enum Agents {
        static let title = "agents_title".localized
        static let headline = "agents_headline".localized
        static let subline = "agents_subline".localized
        static let specialDescription = "agents_special_description".localized
        static let deployAgent = "agents_deploy_agent".localized
        static let dismissAgent = "agents_dismiss_agent".localized
        static let removeFavorite = "agents_remove_favorite".localized
        static let setFavorite = "agents_set_favorite".localized
        static let longPressHint = "agents_long_press_hint".localized
    }
    
    // MARK: - Leaderboard
    enum Leaderboard {
        static let title = "leaderboard_title".localized
        static let tabGlobal = "leaderboard_tab_global".localized
        static let tabYou = "leaderboard_tab_you".localized
        static let globalEmptyTitle = "leaderboard_global_empty_title".localized
        static let globalEmptyDescription = "leaderboard_global_empty_description".localized
        static let youEmptyTitle = "leaderboard_you_empty_title".localized
        static let youEmptyDescription = "leaderboard_you_empty_description".localized
        static func users(_ count: Int) -> String { "leaderboard_users".localized(with: count) }
        static let rateFooter = "leaderboard_rate_footer".localized
    }
    
    // MARK: - Agent Detail
    enum AgentDetail {
        static let completed = "agent_detail_completed".localized
        static let failed = "agent_detail_failed".localized
        static let success = "agent_detail_success".localized
        static let noMissions = "agent_detail_no_missions".localized
        static let missions = "agent_detail_missions".localized
    }
    
    // MARK: - Settings
    enum Settings {
        static let title = "settings_title".localized
        static let sectionAccount = "settings_section_account".localized
        static let sectionPersonalization = "settings_section_personalization".localized
        static let sectionGeneral = "settings_section_general".localized
        static let sectionLegal = "settings_section_legal".localized
        static let customRoast = "settings_custom_roast".localized
        static let customRoastActive = "settings_custom_roast_active".localized
        static let personalizationFooter = "settings_personalization_footer".localized
        static let hapticFeedback = "settings_haptic_feedback".localized
        static let name = "settings_name".localized
        static let nameNotSet = "settings_name_not_set".localized
        static let nameFooter = "settings_name_footer".localized
        static let reviewYap = "settings_review_yap".localized
        static let shareYap = "settings_share_yap".localized
        static let restorePurchases = "settings_restore_purchases".localized
        static let upgrade = "settings_upgrade".localized
        static let accountSynced = "settings_account_synced".localized
        static let unlinkAccount = "settings_unlink_account".localized
        static let unlinkAlertTitle = "settings_unlink_alert_title".localized
        static let unlinkAlertMessage = "settings_unlink_alert_message".localized
        static let unlinkAction = "settings_unlink_action".localized
        static let signInDescription = "settings_sign_in_description".localized
        static let notLinkedFooter = "settings_not_linked_footer".localized
    }
    
    // MARK: - Custom Roast
    enum CustomRoast {
        static let title = "custom_roast_title".localized
        static let placeholder = "custom_roast_placeholder".localized
        static let sectionHeader = "custom_roast_section_header".localized
        static let sectionFooter = "custom_roast_section_footer".localized
        static let clear = "custom_roast_clear".localized
    }
    
    // MARK: - Help
    enum Help {
        static let title = "help_title".localized
        static let sectionCommunity = "help_section_community".localized
        static let communityFooter = "help_community_footer".localized
        static let joinCommunity = "help_join_community".localized
        static let requestFeature = "help_request_feature".localized
        static let sectionFaq = "help_section_faq".localized
        static let faqWhatIsYapQ = "help_faq_what_is_yap_q".localized
        static let faqWhatIsYapA = "help_faq_what_is_yap_a".localized
        static let faqFreePlanQ = "help_faq_free_plan_q".localized
        static let faqFreePlanA = "help_faq_free_plan_a".localized
        static let faqProUnlockQ = "help_faq_pro_unlock_q".localized
        static let faqProUnlockA = "help_faq_pro_unlock_a".localized
        static let faqSpecialAgentsQ = "help_faq_special_agents_q".localized
        static let faqSpecialAgentsA = "help_faq_special_agents_a".localized
        static let faqMissDeadlineQ = "help_faq_miss_deadline_q".localized
        static let faqMissDeadlineA = "help_faq_miss_deadline_a".localized
        static let faqExtendDeadlineQ = "help_faq_extend_deadline_q".localized
        static let faqExtendDeadlineA = "help_faq_extend_deadline_a".localized
        static let faqNightNotificationsQ = "help_faq_night_notifications_q".localized
        static let faqNightNotificationsA = "help_faq_night_notifications_a".localized
        static let faqAgentDifferencesQ = "help_faq_agent_differences_q".localized
        static let faqAgentDifferencesA = "help_faq_agent_differences_a".localized
    }
    
    // MARK: - Paywall
    enum Paywall {
        static let pro = "paywall_pro".localized
        static let headline = "paywall_headline".localized
        static let featureSpecialAgents = "paywall_feature_special_agents".localized
        static let featureAgentMemory = "paywall_feature_agent_memory".localized
        static let featureUnlimitedMissions = "paywall_feature_unlimited_missions".localized
        static func unlockProPrice(_ price: String) -> String { "paywall_unlock_pro_price".localized(with: price) }
        static let oneTimePurchase = "paywall_one_time_purchase".localized
        static let unlockPro = "paywall_unlock_pro".localized
        static let restorePurchase = "paywall_restore_purchase".localized
    }
    
    // MARK: - Comparison Table
    enum Comparison {
        static let free = "comparison_free".localized
        static let pro = "comparison_pro".localized
        static let specialAgents = "comparison_special_agents".localized
        static let missionsPerDay = "comparison_missions_per_day".localized
        static let missionsPerDayFree = "comparison_missions_per_day_free".localized
        static let missionsPerDayPro = "comparison_missions_per_day_pro".localized
        static let aiMessages = "comparison_ai_messages".localized
        static let agentMemory = "comparison_agent_memory".localized
        static let customRoast = "comparison_custom_roast".localized
        static let customDeadline = "comparison_custom_deadline".localized
        static let extend = "comparison_extend".localized
    }
    
    // MARK: - Menu
    enum Menu {
        static let settings = "menu_settings".localized
        static let upgradePlan = "menu_upgrade_plan".localized
        static let helpAndSupport = "menu_help_and_support".localized
    }
    
    // MARK: - Store Errors
    enum StoreError {
        static let general = "store_error_general".localized
        static let noProductNetwork = "store_error_no_product_network".localized
        static let userCancelled = "store_error_user_cancelled".localized
        static let pending = "store_error_pending".localized
        static let notAllowed = "store_error_not_allowed".localized
        static let productUnavailable = "store_error_product_unavailable".localized
        static let networkUnavailable = "store_error_network_unavailable".localized
        static func verificationFailed(_ reason: String?) -> String {
            if let reason {
                return String(format: "store_error_verification_failed_reason".localized, reason)
            } else {
                return "store_error_verification_failed".localized
            }
        }
        static let restoreFailed = "store_error_restore_failed".localized
    }
}

extension String {
    var localized: String {
        NSLocalizedString(self, comment: "")
    }
    
    func localized(with arguments: CVarArg...) -> String {
        String(format: self.localized, arguments: arguments)
    }
}
