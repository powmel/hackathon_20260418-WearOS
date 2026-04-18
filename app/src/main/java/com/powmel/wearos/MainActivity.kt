package com.powmel.wearos

import android.os.Bundle
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import com.google.android.material.button.MaterialButton
import com.powmel.wearos.databinding.ActivityMainBinding

class MainActivity : AppCompatActivity() {
    private lateinit var binding: ActivityMainBinding
    private lateinit var repository: RhinoRepository

    private var state: RhinoState? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        binding = ActivityMainBinding.inflate(layoutInflater)
        setContentView(binding.root)

        repository = RhinoRepository(this)
        state = repository.loadState()

        bindActions()
        render(requireState())
    }

    private fun bindActions() {
        binding.feedButton.setOnClickListener {
            state = repository.feed(requireState())
            render(requireState())
        }

        binding.outfitNoneButton.setOnClickListener { updateOutfit(RhinoOutfit.NONE) }
        binding.outfitCapeButton.setOnClickListener { updateOutfit(RhinoOutfit.CAPE) }
        binding.outfitBowButton.setOnClickListener { updateOutfit(RhinoOutfit.BOW) }
        binding.outfitRainButton.setOnClickListener { updateOutfit(RhinoOutfit.RAINCOAT) }
    }

    private fun updateOutfit(outfit: RhinoOutfit) {
        state = repository.applyOutfit(requireState(), outfit)
        render(requireState())
    }

    private fun render(state: RhinoState) {
        binding.rhinoImage.setImageResource(
            if (state.mood == RhinoMood.SAD) {
                R.drawable.sai_baby_short
            } else {
                R.drawable.sai_baby_middle
            },
        )

        binding.scoreValue.text = getString(R.string.score_value, state.focusScore)
        binding.usageValue.text = getString(R.string.usage_value, state.usageMinutes)
        binding.fullnessValue.text = getString(R.string.fullness_value, state.fullness)
        binding.moodValue.text = state.mood.label
        binding.moodDetail.text = state.mood.detail
        binding.outfitBadge.text = state.outfit.label
        binding.syncValue.text = state.lastSyncedAt

        binding.fullnessProgress.progress = state.fullness
        binding.feedButton.isEnabled = state.focusScore >= RhinoRepository.FEED_COST
        binding.feedButton.text = if (binding.feedButton.isEnabled) {
            getString(R.string.feed_action)
        } else {
            getString(R.string.feed_locked_action)
        }

        val accentColor = when (state.outfit) {
            RhinoOutfit.NONE -> R.color.outfit_none
            RhinoOutfit.CAPE -> R.color.outfit_cape
            RhinoOutfit.BOW -> R.color.outfit_bow
            RhinoOutfit.RAINCOAT -> R.color.outfit_rain
        }
        binding.rhinoCard.strokeColor = ContextCompat.getColor(this, accentColor)

        updateOutfitButtons(state.outfit)
    }

    private fun updateOutfitButtons(selected: RhinoOutfit) {
        updateOutfitButton(binding.outfitNoneButton, selected == RhinoOutfit.NONE, R.color.outfit_none)
        updateOutfitButton(binding.outfitCapeButton, selected == RhinoOutfit.CAPE, R.color.outfit_cape)
        updateOutfitButton(binding.outfitBowButton, selected == RhinoOutfit.BOW, R.color.outfit_bow)
        updateOutfitButton(binding.outfitRainButton, selected == RhinoOutfit.RAINCOAT, R.color.outfit_rain)
    }

    private fun updateOutfitButton(
        button: MaterialButton,
        isSelected: Boolean,
        colorRes: Int,
    ) {
        val fill = ContextCompat.getColor(
            this,
            if (isSelected) colorRes else R.color.surface_soft,
        )
        val text = ContextCompat.getColor(
            this,
            if (isSelected) R.color.text_primary else R.color.text_secondary,
        )
        button.setBackgroundColor(fill)
        button.setTextColor(text)
        button.strokeColor = ContextCompat.getColorStateList(this, colorRes)
        button.strokeWidth = if (isSelected) 4 else 2
    }

    private fun requireState(): RhinoState = checkNotNull(state)
}
