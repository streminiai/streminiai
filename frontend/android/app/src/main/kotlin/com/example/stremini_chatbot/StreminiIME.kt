package com.example.stremini_chatbot

import android.animation.ObjectAnimator
import android.animation.ValueAnimator
import android.content.Context
import android.graphics.Color
import android.inputmethodservice.InputMethodService
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.animation.AccelerateDecelerateInterpolator
import android.view.inputmethod.EditorInfo
import android.widget.*
import androidx.cardview.widget.CardView
import androidx.core.content.ContextCompat
import kotlinx.coroutines.*
import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.util.concurrent.TimeUnit

class StreminiIME : InputMethodService() {

    companion object {
        private const val TAG = "StreminiIME"
        private const val BASE_URL = "https://ai-keyboard-backend.vishwajeetadkine705.workers.dev"
        
        var isActive = false
            private set
    }

    private val serviceScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    private val client = OkHttpClient.Builder()
        .connectTimeout(15, TimeUnit.SECONDS)
        .readTimeout(15, TimeUnit.SECONDS)
        .build()

    // UI Components
    private lateinit var keyboardView: ViewGroup
    private lateinit var inputField: EditText
    private lateinit var suggestionsBar: LinearLayout
    private lateinit var quickActionsBar: LinearLayout
    private lateinit var loadingIndicator: ProgressBar
    
    // State
    private var currentAppContext = "general"
    private var conversationHistory = mutableListOf<String>()
    private var currentSuggestions = listOf<String>()
    private var isLoading = false

    override fun onCreateInputView(): View {
        keyboardView = createModernKeyboardView()
        
        isActive = true
        notifyBubbleStateChange(true)
        
        return keyboardView
    }

    private fun createModernKeyboardView(): ViewGroup {
        val mainLayout = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#000000"))
            setPadding(0, 8, 0, 8)
        }

        // Add AI Input Section
        mainLayout.addView(createAIInputSection())
        
        // Add Suggestions Bar
        mainLayout.addView(createSuggestionsBar())
        
        // Add Quick Actions
        mainLayout.addView(createQuickActionsBar())
        
        // Add Keyboard Keys
        mainLayout.addView(createKeyboardSection())

        return mainLayout
    }

    private fun createAIInputSection(): View {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(12, 8, 12, 8)
            gravity = Gravity.CENTER_VERTICAL
        }

        // Voice button
        val btnVoice = createIconButton(android.R.drawable.ic_btn_speak_now, "#23A6E2") {
            showToast("Voice input coming soon")
        }
        container.addView(btnVoice)

        // Input field container with modern design
        val inputContainer = CardView(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                weight = 1f
                setMargins(8, 0, 8, 0)
            }
            radius = 24f
            cardElevation = 4f
            setCardBackgroundColor(Color.parseColor("#1A1A1A"))
        }

        val inputLayout = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(16, 8, 16, 8)
            gravity = Gravity.CENTER_VERTICAL
        }

        inputField = EditText(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, ViewGroup.LayoutParams.WRAP_CONTENT).apply {
                weight = 1f
            }
            hint = "Type with AI assistance..."
            setHintTextColor(Color.parseColor("#666666"))
            setTextColor(Color.WHITE)
            textSize = 15f
            background = null
            maxLines = 3
            
            addTextChangedListener(object : android.text.TextWatcher {
                override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
                override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
                override fun afterTextChanged(s: android.text.Editable?) {
                    val text = s?.toString() ?: ""
                    if (text.isNotEmpty() && text.length > 2) {
                        getSuggestionsDebounced(text)
                    } else {
                        clearSuggestions()
                    }
                }
            })
        }

        loadingIndicator = ProgressBar(this, null, android.R.attr.progressBarStyleSmall).apply {
            layoutParams = LinearLayout.LayoutParams(24, 24).apply {
                setMargins(8, 0, 0, 0)
            }
            indeterminateDrawable.setColorFilter(
                Color.parseColor("#23A6E2"),
                android.graphics.PorterDuff.Mode.SRC_IN
            )
            visibility = View.GONE
        }

        inputLayout.addView(inputField)
        inputLayout.addView(loadingIndicator)
        inputContainer.addView(inputLayout)
        container.addView(inputContainer)

        // Send button
        val btnSend = createIconButton(android.R.drawable.ic_menu_send, "#23A6E2") {
            commitCurrentText()
        }
        container.addView(btnSend)

        return container
    }

    private fun createSuggestionsBar(): HorizontalScrollView {
        val scrollView = HorizontalScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 8, 0, 8)
            }
            isHorizontalScrollBarEnabled = false
        }

        suggestionsBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(12, 0, 12, 0)
        }

        scrollView.addView(suggestionsBar)
        return scrollView
    }

    private fun createQuickActionsBar(): HorizontalScrollView {
        val scrollView = HorizontalScrollView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 8, 0, 8)
            }
            isHorizontalScrollBarEnabled = false
        }

        quickActionsBar = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            setPadding(12, 0, 12, 0)
            gravity = Gravity.CENTER_VERTICAL
        }

        // Add AI action buttons
        val actions = listOf(
            Triple("✨", "Complete", ::handleComplete),
            Triple("✓", "Correct", ::handleCorrect),
            Triple("🎨", "Tone", ::handleTone),
            Triple("🌐", "Translate", ::handleTranslate),
            Triple("📝", "Expand", ::handleExpand),
            Triple("😊", "Emoji", ::handleEmoji)
        )

        actions.forEach { (icon, label, action) ->
            quickActionsBar.addView(createAIActionButton(icon, label, action))
        }

        scrollView.addView(quickActionsBar)
        return scrollView
    }

    private fun createAIActionButton(icon: String, label: String, action: () -> Unit): View {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(8, 8, 8, 8)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.WRAP_CONTENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(4, 0, 4, 0)
            }
            
            // Ripple effect
            isClickable = true
            isFocusable = true
            background = createRippleDrawable()
            
            setOnClickListener {
                animateClick(this)
                action()
            }
        }

        val iconText = TextView(this).apply {
            text = icon
            textSize = 20f
            gravity = Gravity.CENTER
            setPadding(12, 12, 12, 12)
            setBackgroundResource(android.R.drawable.dialog_holo_light_frame)
            background = createCircleGradientDrawable()
        }

        val labelText = TextView(this).apply {
            text = label
            textSize = 10f
            setTextColor(Color.parseColor("#AAAAAA"))
            gravity = Gravity.CENTER
            setPadding(0, 4, 0, 0)
        }

        container.addView(iconText)
        container.addView(labelText)

        return container
    }

    private fun createKeyboardSection(): View {
        val container = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            setPadding(8, 8, 8, 8)
        }

        // Number row
        container.addView(createKeyRow(listOf("1", "2", "3", "4", "5", "6", "7", "8", "9", "0")))
        
        // Top row
        container.addView(createKeyRow(listOf("q", "w", "e", "r", "t", "y", "u", "i", "o", "p")))
        
        // Middle row
        container.addView(createKeyRow(listOf("a", "s", "d", "f", "g", "h", "j", "k", "l"), 0.5f))
        
        // Bottom row with shift and backspace
        val bottomRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 4, 0, 4)
            }
        }

        // Shift key
        bottomRow.addView(createSpecialKey("⇧", 1.5f) {
            // Toggle shift
        })

        listOf("z", "x", "c", "v", "b", "n", "m").forEach { key ->
            bottomRow.addView(createKey(key))
        }

        // Backspace key
        bottomRow.addView(createSpecialKey("⌫", 1.5f) {
            deleteText()
        })

        container.addView(bottomRow)

        // Space row
        val spaceRow = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 4, 0, 0)
            }
        }

        spaceRow.addView(createSpecialKey("?123", 1.2f) {
            // Toggle numbers/symbols
        })
        
        spaceRow.addView(createSpecialKey(",", 1f) {
            commitText(",")
        })
        
        spaceRow.addView(createSpecialKey("Space", 4f) {
            commitText(" ")
        })
        
        spaceRow.addView(createSpecialKey(".", 1f) {
            commitText(".")
        })
        
        spaceRow.addView(createSpecialKey("↵", 1.5f) {
            sendDefaultEditorAction(true)
        })

        container.addView(spaceRow)

        return container
    }

    private fun createKeyRow(keys: List<String>, startWeight: Float = 0f): View {
        val row = LinearLayout(this).apply {
            orientation = LinearLayout.HORIZONTAL
            layoutParams = LinearLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.WRAP_CONTENT
            ).apply {
                setMargins(0, 4, 0, 4)
            }
        }

        if (startWeight > 0) {
            row.addView(Space(this).apply {
                layoutParams = LinearLayout.LayoutParams(0, 1).apply {
                    weight = startWeight
                }
            })
        }

        keys.forEach { key ->
            row.addView(createKey(key))
        }

        if (startWeight > 0) {
            row.addView(Space(this).apply {
                layoutParams = LinearLayout.LayoutParams(0, 1).apply {
                    weight = startWeight
                }
            })
        }

        return row
    }

    private fun createKey(key: String): View {
        return TextView(this).apply {
            text = key
            textSize = 18f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, 120).apply {
                weight = 1f
                setMargins(2, 2, 2, 2)
            }
            background = createKeyBackgroundDrawable()
            isClickable = true
            isFocusable = true
            
            setOnClickListener {
                animateKeyPress(this)
                commitText(key)
                inputField.append(key)
            }
        }
    }

    private fun createSpecialKey(label: String, weight: Float, action: () -> Unit): View {
        return TextView(this).apply {
            text = label
            textSize = 16f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
            layoutParams = LinearLayout.LayoutParams(0, 120).apply {
                this.weight = weight
                setMargins(2, 2, 2, 2)
            }
            background = createSpecialKeyBackgroundDrawable()
            isClickable = true
            isFocusable = true
            
            setOnClickListener {
                animateKeyPress(this)
                action()
            }
        }
    }

    private fun createIconButton(icon: Int, color: String, action: () -> Unit): View {
        return ImageButton(this).apply {
            setImageResource(icon)
            setColorFilter(Color.parseColor(color))
            layoutParams = LinearLayout.LayoutParams(48, 48).apply {
                setMargins(4, 0, 4, 0)
            }
            background = createCircleGradientDrawable()
            scaleType = ImageView.ScaleType.FIT_CENTER
            setPadding(8, 8, 8, 8)
            
            setOnClickListener {
                animateClick(this)
                action()
            }
        }
    }

    // Drawable creators
    private fun createKeyBackgroundDrawable() = android.graphics.drawable.GradientDrawable().apply {
        shape = android.graphics.drawable.GradientDrawable.RECTANGLE
        setColor(Color.parseColor("#1A1A1A"))
        cornerRadius = 12f
        setStroke(1, Color.parseColor("#333333"))
    }

    private fun createSpecialKeyBackgroundDrawable() = android.graphics.drawable.GradientDrawable().apply {
        shape = android.graphics.drawable.GradientDrawable.RECTANGLE
        setColor(Color.parseColor("#2A2A2A"))
        cornerRadius = 12f
        setStroke(1, Color.parseColor("#444444"))
    }

    private fun createCircleGradientDrawable() = android.graphics.drawable.GradientDrawable().apply {
        shape = android.graphics.drawable.GradientDrawable.OVAL
        colors = intArrayOf(
            Color.parseColor("#23A6E2"),
            Color.parseColor("#0066FF")
        )
    }

    private fun createRippleDrawable(): android.graphics.drawable.Drawable {
        val shape = android.graphics.drawable.GradientDrawable().apply {
            shape = android.graphics.drawable.GradientDrawable.RECTANGLE
            cornerRadius = 12f
            setColor(Color.TRANSPARENT)
        }
        return android.graphics.drawable.RippleDrawable(
            android.content.res.ColorStateList.valueOf(Color.parseColor("#3323A6E2")),
            shape,
            null
        )
    }

    // Animations
    private fun animateKeyPress(view: View) {
        val scaleDown = ObjectAnimator.ofFloat(view, "scaleX", 1f, 0.9f)
        val scaleUp = ObjectAnimator.ofFloat(view, "scaleX", 0.9f, 1f)
        scaleDown.duration = 50
        scaleUp.duration = 50
        scaleDown.interpolator = AccelerateDecelerateInterpolator()
        scaleUp.interpolator = AccelerateDecelerateInterpolator()
        
        scaleDown.start()
        scaleDown.addListener(object : android.animation.AnimatorListenerAdapter() {
            override fun onAnimationEnd(animation: android.animation.Animator) {
                scaleUp.start()
            }
        })
    }

    private fun animateClick(view: View) {
        view.animate()
            .scaleX(0.9f)
            .scaleY(0.9f)
            .setDuration(100)
            .withEndAction {
                view.animate()
                    .scaleX(1f)
                    .scaleY(1f)
                    .setDuration(100)
                    .start()
            }
            .start()
    }

    // AI Functions
    private var suggestionsJob: Job? = null

    private fun getSuggestionsDebounced(text: String) {
        suggestionsJob?.cancel()
        suggestionsJob = serviceScope.launch {
            delay(500) // Debounce
            getSuggestions(text)
        }
    }

    private fun getSuggestions(text: String) {
        if (isLoading) return
        
        serviceScope.launch(Dispatchers.IO) {
            try {
                setLoading(true)
                
                val requestJson = JSONObject().apply {
                    put("text", text)
                    put("context", conversationHistory.takeLast(3).joinToString(" "))
                    put("appContext", currentAppContext)
                    put("count", 3)
                }

                val request = Request.Builder()
                    .url("$BASE_URL/keyboard/suggest")
                    .post(requestJson.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    val json = JSONObject(response.body?.string() ?: "")
                    val suggestions = json.optJSONArray("suggestions")
                    
                    val suggestionsList = mutableListOf<String>()
                    if (suggestions != null) {
                        for (i in 0 until suggestions.length()) {
                            suggestionsList.add(suggestions.getString(i))
                        }
                    }
                    
                    withContext(Dispatchers.Main) {
                        displaySuggestions(suggestionsList)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Suggestions error", e)
            } finally {
                setLoading(false)
            }
        }
    }

    private fun displaySuggestions(suggestions: List<String>) {
        suggestionsBar.removeAllViews()
        currentSuggestions = suggestions
        
        suggestions.forEach { suggestion ->
            val chip = TextView(this).apply {
                text = suggestion
                textSize = 14f
                setTextColor(Color.WHITE)
                setPadding(20, 10, 20, 10)
                layoutParams = LinearLayout.LayoutParams(
                    ViewGroup.LayoutParams.WRAP_CONTENT,
                    ViewGroup.LayoutParams.WRAP_CONTENT
                ).apply {
                    setMargins(4, 0, 4, 0)
                }
                background = createSuggestionChipDrawable()
                isClickable = true
                
                setOnClickListener {
                    inputField.setText(suggestion)
                    inputField.setSelection(suggestion.length)
                    clearSuggestions()
                }
            }
            
            suggestionsBar.addView(chip)
        }
    }

    private fun createSuggestionChipDrawable() = android.graphics.drawable.GradientDrawable().apply {
        shape = android.graphics.drawable.GradientDrawable.RECTANGLE
        cornerRadius = 20f
        colors = intArrayOf(
            Color.parseColor("#1A23A6E2"),
            Color.parseColor("#1A0066FF")
        )
        setStroke(1, Color.parseColor("#23A6E2"))
    }

    private fun clearSuggestions() {
        suggestionsBar.removeAllViews()
        currentSuggestions = emptyList()
    }

    private fun setLoading(loading: Boolean) {
        isLoading = loading
        serviceScope.launch(Dispatchers.Main) {
            loadingIndicator.visibility = if (loading) View.VISIBLE else View.GONE
        }
    }

    // Action handlers
    private fun handleComplete() {
        val text = inputField.text.toString()
        if (text.isEmpty()) return
        
        serviceScope.launch(Dispatchers.IO) {
            try {
                val requestJson = JSONObject().apply {
                    put("text", text)
                    put("context", conversationHistory.takeLast(3).joinToString(" "))
                }

                val request = Request.Builder()
                    .url("$BASE_URL/keyboard/complete")
                    .post(requestJson.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    val json = JSONObject(response.body?.string() ?: "")
                    val completion = json.optString("completion", "")
                    
                    withContext(Dispatchers.Main) {
                        inputField.setText(completion)
                        inputField.setSelection(completion.length)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Complete error", e)
            }
        }
    }

    private fun handleCorrect() {
        val text = inputField.text.toString()
        if (text.isEmpty()) return
        
        serviceScope.launch(Dispatchers.IO) {
            try {
                val requestJson = JSONObject().apply {
                    put("text", text)
                    put("language", "en")
                }

                val request = Request.Builder()
                    .url("$BASE_URL/keyboard/correct")
                    .post(requestJson.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    val json = JSONObject(response.body?.string() ?: "")
                    val corrected = json.optString("corrected", "")
                    
                    withContext(Dispatchers.Main) {
                        inputField.setText(corrected)
                        inputField.setSelection(corrected.length)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Correct error", e)
            }
        }
    }

    private fun handleTone() {
        val text = inputField.text.toString()
        if (text.isEmpty()) return
        
        val tones = arrayOf("professional", "casual", "friendly", "formal", "polite", "confident")
        
        val builder = android.app.AlertDialog.Builder(this, android.R.style.Theme_DeviceDefault_Dialog_Alert)
        builder.setTitle("Select Tone")
        builder.setItems(tones) { _, which ->
            changeTone(text, tones[which])
        }
        builder.show()
    }

    private fun changeTone(text: String, tone: String) {
        serviceScope.launch(Dispatchers.IO) {
            try {
                val requestJson = JSONObject().apply {
                    put("text", text)
                    put("tone", tone)
                }

                val request = Request.Builder()
                    .url("$BASE_URL/keyboard/tone")
                    .post(requestJson.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    val json = JSONObject(response.body?.string() ?: "")
                    val rewritten = json.optString("rewritten", "")
                    
                    withContext(Dispatchers.Main) {
                        inputField.setText(rewritten)
                        inputField.setSelection(rewritten.length)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Tone error", e)
            }
        }
    }

    private fun handleTranslate() {
        val text = inputField.text.toString()
        if (text.isEmpty()) return
        
        val languages = arrayOf("Hindi", "Spanish", "French", "German", "Chinese")
        val langCodes = arrayOf("hi", "es", "fr", "de", "zh")
        
        val builder = android.app.AlertDialog.Builder(this, android.R.style.Theme_DeviceDefault_Dialog_Alert)
        builder.setTitle("Translate to")
        builder.setItems(languages) { _, which ->
            translateText(text, langCodes[which])
        }
        builder.show()
    }

    private fun translateText(text: String, targetLang: String) {
        serviceScope.launch(Dispatchers.IO) {
            try {
                val requestJson = JSONObject().apply {
                    put("text", text)
                    put("targetLanguage", targetLang)
                }

                val request = Request.Builder()
                    .url("$BASE_URL/keyboard/translate")
                    .post(requestJson.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    val json = JSONObject(response.body?.string() ?: "")
                    val translation = json.optString("translation", "")
                    
                    withContext(Dispatchers.Main) {
                        inputField.setText(translation)
                        inputField.setSelection(translation.length)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Translation error", e)
            }
        }
    }

    private fun handleExpand() {
        val text = inputField.text.toString()
        if (text.isEmpty()) return
        
        serviceScope.launch(Dispatchers.IO) {
            try {
                val requestJson = JSONObject().apply {
                    put("text", text)
                    put("targetLength", "medium")
                }

                val request = Request.Builder()
                    .url("$BASE_URL/keyboard/expand")
                    .post(requestJson.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    val json = JSONObject(response.body?.string() ?: "")
                    val expanded = json.optString("expanded", "")
                    
                    withContext(Dispatchers.Main) {
                        inputField.setText(expanded)
                        inputField.setSelection(expanded.length)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Expand error", e)
            }
        }
    }

    private fun handleEmoji() {
        val text = inputField.text.toString()
        if (text.isEmpty()) return
        
        serviceScope.launch(Dispatchers.IO) {
            try {
                val requestJson = JSONObject().apply {
                    put("text", text)
                    put("count", 5)
                }

                val request = Request.Builder()
                    .url("$BASE_URL/keyboard/emoji")
                    .post(requestJson.toString().toRequestBody("application/json".toMediaType()))
                    .build()

                val response = client.newCall(request).execute()
                if (response.isSuccessful) {
                    val json = JSONObject(response.body?.string() ?: "")
                    val emojis = json.optJSONArray("emojis")
                    
                    val emojiList = mutableListOf<String>()
                    if (emojis != null) {
                        for (i in 0 until emojis.length()) {
                            emojiList.add(emojis.getString(i))
                        }
                    }
                    
                    withContext(Dispatchers.Main) {
                        showEmojiPicker(emojiList)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Emoji error", e)
            }
        }
    }

    private fun showEmojiPicker(emojis: List<String>) {
        val builder = android.app.AlertDialog.Builder(this, android.R.style.Theme_DeviceDefault_Dialog_Alert)
        builder.setTitle("Select Emoji")
        builder.setItems(emojis.toTypedArray()) { _, which ->
            val currentText = inputField.text.toString()
            inputField.setText("$currentText ${emojis[which]}")
            inputField.setSelection(inputField.text.length)
        }
        builder.show()
    }

    // Input methods
    private fun commitText(text: String) {
        currentInputConnection?.commitText(text, 1)
    }

    private fun commitCurrentText() {
        val text = inputField.text.toString()
        if (text.isNotEmpty()) {
            commitText(text)
            inputField.setText("")
            conversationHistory.add(text)
            if (conversationHistory.size > 10) {
                conversationHistory.removeAt(0)
            }
        }
    }

    private fun deleteText() {
        currentInputConnection?.deleteSurroundingText(1, 0)
        val text = inputField.text.toString()
        if (text.isNotEmpty()) {
            inputField.setText(text.substring(0, text.length - 1))
        }
    }

    private fun showToast(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }

    private fun notifyBubbleStateChange(active: Boolean) {
        val intent = android.content.Intent("com.example.stremini_chatbot.KEYBOARD_STATE_CHANGED")
        intent.putExtra("isActive", active)
        sendBroadcast(intent)
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        
        currentAppContext = when (info?.packageName) {
            "com.whatsapp", "com.facebook.orca" -> "messaging"
            "com.android.chrome", "com.android.browser" -> "search"
            "com.google.android.gm" -> "email"
            else -> "general"
        }
        
        inputField.setText("")
        clearSuggestions()
    }

    override fun onDestroy() {
        super.onDestroy()
        serviceScope.cancel()
        isActive = false
        notifyBubbleStateChange(false)
    }
}
