package com.example.stremini_chatbot

import android.inputmethodservice.InputMethodService
import android.view.View
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputConnection
import android.widget.*
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

    private lateinit var keyboardView: View
    private lateinit var inputField: EditText
    private lateinit var suggestionsBar: LinearLayout
    private lateinit var quickActionsBar: LinearLayout
    
    private var currentAppContext = "general"
    private var conversationHistory = mutableListOf<String>()

    override fun onCreateInputView(): View {
        keyboardView = layoutInflater.inflate(R.layout.keyboard_layout, null)
        
        inputField = keyboardView.findViewById(R.id.keyboard_input)
        suggestionsBar = keyboardView.findViewById(R.id.suggestions_bar)
        quickActionsBar = keyboardView.findViewById(R.id.quick_actions_bar)
        
        setupKeyboard()
        setupQuickActions()
        
        isActive = true
        notifyBubbleStateChange(true)
        
        return keyboardView
    }

    private fun setupKeyboard() {
        // Number row
        setupKey(R.id.key_1, "1")
        setupKey(R.id.key_2, "2")
        setupKey(R.id.key_3, "3")
        setupKey(R.id.key_4, "4")
        setupKey(R.id.key_5, "5")
        setupKey(R.id.key_6, "6")
        setupKey(R.id.key_7, "7")
        setupKey(R.id.key_8, "8")
        setupKey(R.id.key_9, "9")
        setupKey(R.id.key_0, "0")
        
        // Top row
        setupKey(R.id.key_q, "q")
        setupKey(R.id.key_w, "w")
        setupKey(R.id.key_e, "e")
        setupKey(R.id.key_r, "r")
        setupKey(R.id.key_t, "t")
        setupKey(R.id.key_y, "y")
        setupKey(R.id.key_u, "u")
        setupKey(R.id.key_i, "i")
        setupKey(R.id.key_o, "o")
        setupKey(R.id.key_p, "p")
        
        // Middle row
        setupKey(R.id.key_a, "a")
        setupKey(R.id.key_s, "s")
        setupKey(R.id.key_d, "d")
        setupKey(R.id.key_f, "f")
        setupKey(R.id.key_g, "g")
        setupKey(R.id.key_h, "h")
        setupKey(R.id.key_j, "j")
        setupKey(R.id.key_k, "k")
        setupKey(R.id.key_l, "l")
        
        // Bottom row
        setupKey(R.id.key_z, "z")
        setupKey(R.id.key_x, "x")
        setupKey(R.id.key_c, "c")
        setupKey(R.id.key_v, "v")
        setupKey(R.id.key_b, "b")
        setupKey(R.id.key_n, "n")
        setupKey(R.id.key_m, "m")
        
        // Special keys
        keyboardView.findViewById<Button>(R.id.key_space).setOnClickListener {
            commitText(" ")
        }
        
        keyboardView.findViewById<Button>(R.id.key_backspace).setOnClickListener {
            deleteText()
        }
        
        keyboardView.findViewById<Button>(R.id.key_enter).setOnClickListener {
            commitText("\n")
        }
        
        // Text change listener for suggestions
        inputField.addTextChangedListener(object : android.text.TextWatcher {
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
            override fun afterTextChanged(s: android.text.Editable?) {
                val text = s?.toString() ?: ""
                if (text.isNotEmpty()) {
                    getSuggestions(text)
                } else {
                    clearSuggestions()
                }
            }
        })
    }

    private fun setupKey(id: Int, char: String) {
        keyboardView.findViewById<Button>(id)?.setOnClickListener {
            commitText(char)
            inputField.append(char)
        }
    }

    private fun setupQuickActions() {
        keyboardView.findViewById<ImageButton>(R.id.btn_complete).setOnClickListener {
            val text = inputField.text.toString()
            if (text.isNotEmpty()) {
                completeText(text)
            }
        }
        
        keyboardView.findViewById<ImageButton>(R.id.btn_translate).setOnClickListener {
            val text = inputField.text.toString()
            if (text.isNotEmpty()) {
                showTranslateDialog(text)
            }
        }
        
        keyboardView.findViewById<ImageButton>(R.id.btn_tone).setOnClickListener {
            val text = inputField.text.toString()
            if (text.isNotEmpty()) {
                showToneDialog(text)
            }
        }
        
        keyboardView.findViewById<ImageButton>(R.id.btn_expand).setOnClickListener {
            val text = inputField.text.toString()
            if (text.isNotEmpty()) {
                expandText(text)
            }
        }
        
        keyboardView.findViewById<ImageButton>(R.id.btn_correct).setOnClickListener {
            val text = inputField.text.toString()
            if (text.isNotEmpty()) {
                correctText(text)
            }
        }
    }

    private fun commitText(text: String) {
        currentInputConnection?.commitText(text, 1)
    }

    private fun deleteText() {
        currentInputConnection?.deleteSurroundingText(1, 0)
    }

    // ========================================
    // AI FEATURES
    // ========================================

    private fun getSuggestions(text: String) {
        serviceScope.launch(Dispatchers.IO) {
            try {
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
                    
                    withContext(Dispatchers.Main) {
                        displaySuggestions(suggestions)
                    }
                }
            } catch (e: Exception) {
                android.util.Log.e(TAG, "Suggestions error", e)
            }
        }
    }

    private fun completeText(text: String) {
        serviceScope.launch(Dispatchers.IO) {
            try {
                val requestJson = JSONObject().apply {
                    put("text", text)
                    put("context", conversationHistory.takeLast(3).joinToString(" "))
                    put("appContext", currentAppContext)
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

    private fun correctText(text: String) {
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

    private fun expandText(text: String) {
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

    private fun showToneDialog(text: String) {
        val tones = arrayOf("professional", "casual", "friendly", "formal", "polite", "confident")
        
        val builder = android.app.AlertDialog.Builder(this)
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
                android.util.Log.e(TAG, "Tone change error", e)
            }
        }
    }

    private fun showTranslateDialog(text: String) {
        val languages = arrayOf("Hindi", "Spanish", "French", "German", "Chinese")
        val langCodes = arrayOf("hi", "es", "fr", "de", "zh")
        
        val builder = android.app.AlertDialog.Builder(this)
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

    private fun displaySuggestions(suggestions: org.json.JSONArray?) {
        suggestionsBar.removeAllViews()
        
        if (suggestions == null || suggestions.length() == 0) return
        
        for (i in 0 until suggestions.length()) {
            val suggestion = suggestions.getString(i)
            
            val button = Button(this).apply {
                text = suggestion
                setPadding(24, 12, 24, 12)
                setBackgroundColor(android.graphics.Color.parseColor("#1A1A1A"))
                setTextColor(android.graphics.Color.WHITE)
                textSize = 14f
            }
            
            button.setOnClickListener {
                inputField.setText(suggestion)
                inputField.setSelection(suggestion.length)
            }
            
            suggestionsBar.addView(button)
        }
    }

    private fun clearSuggestions() {
        suggestionsBar.removeAllViews()
    }

    private fun notifyBubbleStateChange(active: Boolean) {
        val intent = android.content.Intent("com.example.stremini_chatbot.KEYBOARD_STATE_CHANGED")
        intent.putExtra("isActive", active)
        sendBroadcast(intent)
    }

    override fun onStartInputView(info: EditorInfo?, restarting: Boolean) {
        super.onStartInputView(info, restarting)
        
        // Detect app context
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
