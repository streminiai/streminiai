package com.example.stremini_chatbot

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import android.view.inputmethod.InputMethodManager
import android.widget.*
import androidx.appcompat.app.AppCompatActivity

class KeyboardSettingsActivity : AppCompatActivity() {

    private lateinit var toggleKeyboard: Switch
    private lateinit var btnEnableKeyboard: Button
    private lateinit var btnSelectKeyboard: Button
    private lateinit var themeGroup: RadioGroup
    private lateinit var layoutInfo: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_keyboard_settings)

        initViews()
        setupListeners()
        updateStatus()
    }

    private fun initViews() {
        toggleKeyboard = findViewById(R.id.toggle_keyboard)
        btnEnableKeyboard = findViewById(R.id.btn_enable_keyboard)
        btnSelectKeyboard = findViewById(R.id.btn_select_keyboard)
        themeGroup = findViewById(R.id.theme_group)
        layoutInfo = findViewById(R.id.layout_info)

        // Back button
        findViewById<ImageButton>(R.id.btn_back)?.setOnClickListener {
            finish()
        }
    }

    private fun setupListeners() {
        toggleKeyboard.setOnCheckedChangeListener { _, isChecked ->
            if (isChecked && !isKeyboardEnabled()) {
                Toast.makeText(
                    this,
                    "Please enable Stremini AI Keyboard in settings first",
                    Toast.LENGTH_SHORT
                ).show()
                toggleKeyboard.isChecked = false
                openKeyboardSettings()
            }
        }

        btnEnableKeyboard.setOnClickListener {
            openKeyboardSettings()
        }

        btnSelectKeyboard.setOnClickListener {
            showInputMethodPicker()
        }

        // Theme selection
        themeGroup.setOnCheckedChangeListener { _, checkedId ->
            when (checkedId) {
                R.id.theme_dark -> applyTheme("dark")
                R.id.theme_blue -> applyTheme("blue")
                R.id.theme_purple -> applyTheme("purple")
            }
        }
    }

    private fun updateStatus() {
        val enabled = isKeyboardEnabled()
        val selected = isKeyboardSelected()

        toggleKeyboard.isChecked = enabled && selected
        
        layoutInfo.text = buildString {
            append("Status:\n")
            append("• Enabled: ${if (enabled) "✓ Yes" else "✗ No"}\n")
            append("• Selected: ${if (selected) "✓ Yes" else "✗ No"}\n")
            append("\nFeatures:\n")
            append("• Smart Text Completion\n")
            append("• Grammar Correction\n")
            append("• Multi-language Translation\n")
            append("• Tone Adjustment\n")
            append("• Text Expansion\n")
            append("• Emoji Suggestions\n")
        }
    }

    private fun isKeyboardEnabled(): Boolean {
        val imeManager = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        val enabledInputMethods = imeManager.enabledInputMethodList
        val packageName = packageName
        
        return enabledInputMethods.any { 
            it.packageName == packageName 
        }
    }

    private fun isKeyboardSelected(): Boolean {
        val imeManager = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        val currentInputMethod = Settings.Secure.getString(
            contentResolver,
            Settings.Secure.DEFAULT_INPUT_METHOD
        )
        
        return currentInputMethod?.contains(packageName) == true
    }

    private fun openKeyboardSettings() {
        val intent = Intent(Settings.ACTION_INPUT_METHOD_SETTINGS)
        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        startActivity(intent)
        
        Toast.makeText(
            this,
            "Find 'Stremini AI Keyboard' and enable it",
            Toast.LENGTH_LONG
        ).show()
    }

    private fun showInputMethodPicker() {
        val imeManager = getSystemService(INPUT_METHOD_SERVICE) as InputMethodManager
        imeManager.showInputMethodPicker()
    }

    private fun applyTheme(theme: String) {
        // Save theme preference
        getSharedPreferences("keyboard_prefs", MODE_PRIVATE)
            .edit()
            .putString("theme", theme)
            .apply()
        
        Toast.makeText(
            this,
            "Theme changed to $theme",
            Toast.LENGTH_SHORT
        ).show()
    }

    override fun onResume() {
        super.onResume()
        updateStatus()
    }
}
