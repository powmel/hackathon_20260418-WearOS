package com.powmel.wearos

import android.content.Context
import android.content.SharedPreferences
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

data class RhinoState(
    val focusScore: Int,
    val usageMinutes: Int,
    val fullness: Int,
    val mood: RhinoMood,
    val outfit: RhinoOutfit,
    val lastSyncedAt: String,
)

enum class RhinoMood(
    val label: String,
    val detail: String,
) {
    HAPPY("楽しそう", "今日は集中できていてご機嫌"),
    CALM("ふつう", "少し疲れているけどまだ元気"),
    SAD("泣きそう", "使いすぎでしょんぼりしている"),
}

enum class RhinoOutfit(
    val label: String,
) {
    NONE("はだか"),
    CAPE("ケープ"),
    BOW("リボン"),
    RAINCOAT("レインコート"),
}

class RhinoRepository(context: Context) {
    private val prefs: SharedPreferences =
        context.getSharedPreferences("rhino_wear_state", Context.MODE_PRIVATE)

    fun loadState(): RhinoState {
        val score = prefs.getInt(KEY_SCORE, 72)
        val usageMinutes = prefs.getInt(KEY_USAGE_MINUTES, 94)
        val fullness = prefs.getInt(KEY_FULLNESS, 66)
        val outfit = RhinoOutfit.valueOf(
            prefs.getString(KEY_OUTFIT, RhinoOutfit.CAPE.name) ?: RhinoOutfit.CAPE.name,
        )
        val lastSyncedAt = prefs.getString(KEY_SYNCED_AT, nowLabel()) ?: nowLabel()

        return RhinoState(
            focusScore = score,
            usageMinutes = usageMinutes,
            fullness = fullness,
            mood = deriveMood(score = score, usageMinutes = usageMinutes, fullness = fullness),
            outfit = outfit,
            lastSyncedAt = lastSyncedAt,
        )
    }

    fun feed(state: RhinoState): RhinoState {
        if (state.focusScore < FEED_COST) return state

        val nextScore = (state.focusScore - FEED_COST).coerceIn(0, 100)
        val nextFullness = (state.fullness + 20).coerceIn(0, 100)
        val updated = state.copy(
            focusScore = nextScore,
            fullness = nextFullness,
            mood = deriveMood(
                score = nextScore,
                usageMinutes = state.usageMinutes,
                fullness = nextFullness,
            ),
            lastSyncedAt = "watch update ${nowLabel()}",
        )
        save(updated)
        return updated
    }

    fun applyOutfit(state: RhinoState, outfit: RhinoOutfit): RhinoState {
        val updated = state.copy(
            outfit = outfit,
            mood = deriveMood(
                score = state.focusScore,
                usageMinutes = state.usageMinutes,
                fullness = state.fullness,
            ),
            lastSyncedAt = "watch outfit ${nowLabel()}",
        )
        save(updated)
        return updated
    }

    private fun save(state: RhinoState) {
        prefs.edit()
            .putInt(KEY_SCORE, state.focusScore)
            .putInt(KEY_USAGE_MINUTES, state.usageMinutes)
            .putInt(KEY_FULLNESS, state.fullness)
            .putString(KEY_OUTFIT, state.outfit.name)
            .putString(KEY_SYNCED_AT, state.lastSyncedAt)
            .apply()
    }

    private fun deriveMood(
        score: Int,
        usageMinutes: Int,
        fullness: Int,
    ): RhinoMood {
        val balance = score + fullness - (usageMinutes / 3)
        return when {
            balance >= 85 -> RhinoMood.HAPPY
            balance >= 45 -> RhinoMood.CALM
            else -> RhinoMood.SAD
        }
    }

    private fun nowLabel(): String {
        return SimpleDateFormat("HH:mm", Locale.JAPAN).format(Date())
    }

    companion object {
        const val FEED_COST = 12

        private const val KEY_SCORE = "score"
        private const val KEY_USAGE_MINUTES = "usage_minutes"
        private const val KEY_FULLNESS = "fullness"
        private const val KEY_OUTFIT = "outfit"
        private const val KEY_SYNCED_AT = "synced_at"
    }
}
