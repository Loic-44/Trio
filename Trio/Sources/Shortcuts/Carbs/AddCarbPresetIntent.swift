import AppIntents
import Foundation
import Intents
import Swinject

struct AddCarbPresetIntent: AppIntent {
    // Title of the action in the Shortcuts app
    static var title: LocalizedStringResource = "Add carbs"

    // Description of the action in the Shortcuts app
    static var description = IntentDescription(LocalizedStringResource("Allow to add carbs in Trio."))

    @Parameter(
        title: "Quantity Carbs",
        description: "Quantity of carbs in g",
        controlStyle: .field,
        inclusiveRange: (lowerBound: 0, upperBound: 300),
    ) var carbQuantity: Double?
        requestValueDialog: IntentDialog(stringLiteral: String(localized: "How many grams of carbs?"))

    @Parameter(
        title: "Quantity Fat",
        description: "Quantity of fat in g",
        default: 0.0,
        inclusiveRange: (0, 300),
    ) var fatQuantity: Double
        requestValueDialog: IntentDialog(stringLiteral: String(localized: "How many grams of fat?"))

    @Parameter(
        title: "Quantity Protein",
        description: "Quantity of Protein in g",
        default: 0.0,
        inclusiveRange: (0, 300),
    ) var proteinQuantity: Double
        requestValueDialog: IntentDialog(stringLiteral: String(localized: "How many grams of protein?"))

    @Parameter(
        title: "Date",
        description: "Date of adding",
        requestValueDialog: IntentDialog(stringLiteral: String(localized: "When did you eat ?"))
    ) var dateAdded: Date?

    @Parameter(
        title: "Notes",
        description: "Emoji or short text"
    ) var note: String?

    @Parameter(
        title: "Confirm Before Logging",
        description: "If toggled, you will need to confirm before logging",
        default: true
    ) var confirmBeforeApplying: Bool

    static var parameterSummary: some ParameterSummary {
        When(\.$confirmBeforeApplying, .equalTo, true, {
            Summary("Log \(\.$carbQuantity) at \(\.$dateAdded)") {
                \.$fatQuantity
                \.$proteinQuantity
                \.$note
                \.$confirmBeforeApplying
            }
        }, otherwise: {
            Summary("Immediately Log \(\.$carbQuantity) at \(\.$dateAdded)") {
                \.$fatQuantity
                \.$proteinQuantity
                \.$note
                \.$confirmBeforeApplying
            }
        })
    }

    @MainActor func perform() async throws -> some ProvidesDialog {
        do {
            let quantityCarbs: Double
            if let cq = carbQuantity {
                quantityCarbs = cq
            } else {
                quantityCarbs = try await $carbQuantity.requestValue("How many grams of carbs?")
            }

            let dateCarbsAdded: Date
            let dateDefinedByUser: Bool
            if let da = dateAdded {
                dateCarbsAdded = da
                dateDefinedByUser = true
            } else {
                dateCarbsAdded = Date()
                dateDefinedByUser = false
            }

            let quantityCarbsName = quantityCarbs.toString()
            if confirmBeforeApplying {
                try await requestConfirmation(
                    result: .result(
                        dialog: IntentDialog(stringLiteral: String(localized: "Add \(quantityCarbsName) grams of carbs?"))
                    )
                )
            }

            let finalQuantityCarbsDisplay = try await CarbPresetIntentRequest().addCarbs(
                quantityCarbs,
                fatQuantity,
                proteinQuantity,
                dateCarbsAdded,
                note,
                dateDefinedByUser
            )
            return .result(
                dialog: IntentDialog(stringLiteral: finalQuantityCarbsDisplay)
            )

        } catch {
            throw error
        }
    }
}
