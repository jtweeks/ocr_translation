# OCR & On-Device Translation App

## Summary

This Flutter application allows users to point their device's camera at text in one language, have it recognized (OCR), and then see an on-device translation into another language in near real-time. Users can also manually type text for translation and save captured translations to a list for later review.

The application leverages Google's ML Kit for both on-device text recognition from the camera stream and on-device translation, enabling offline functionality once the necessary language models are downloaded.

## Features

*   **Live OCR:** Recognizes text directly from the live camera feed.
*   **On-Device Translation:** Translates recognized or manually entered text without needing a constant internet connection (after initial model download).
*   **Manual Text Entry:** Users can type or paste text into the "Original Text" field.
*   **Automatic Translation:** Text in the "Original Text" field (whether from OCR or manual input) is automatically translated if it meets minimum length requirements.
*   **Capture Translations:** Save original and translated text pairs to a persistent list.
*   **View Saved Translations:** Browse previously captured translations.
*   **Language Model Management:** Prompts for and allows downloading of necessary language models for on-device translation.

## Technology Used

*   **Flutter:** For cross-platform (iOS & Android) application development.
*   **Dart:** Programming language for Flutter.
*   **Google ML Kit:**
    *   **Text Recognition (OCR):** `google_mlkit_text_recognition` package for identifying text from camera frames or static images.
    *   **On-Device Translation:** `google_mlkit_translation` package for translating text between various languages locally on the device.
*   **Camera Plugin (`camera`):** To access and stream the device camera feed.
*   **State Management:** (Implicitly using `StatefulWidget` and `setState`. If you evolve this, you might mention Provider, Riverpod, BLoC, etc.)
*   **Debouncing:** To manage the frequency of translation API calls during text input.

## App Flow & Instructions

### 1. Initial Setup & Model Downloads

When you first open the app or access the camera/translation feature, it will check if the required language models for translation (e.g., English, Spanish) are downloaded.

*   If models are not present, you might be prompted, or you can tap the **Download Icon** in the AppBar to initiate model downloads. An internet connection is required for this initial download.

### 2. Using the Camera for OCR & Translation

1.  **Open Camera View:** Tap the **Camera Icon** (`add_a_photo_outlined` or `camera_alt`) in the AppBar.

    *(Placeholder for: Screenshot of Main Screen with Camera Icon highlighted)*
    `![Main Screen with Camera Icon](./assets/screengrabs/screen1.jpg)`

2.  **Point at Text:** Aim your device's camera at the text you want to recognize and translate.
    *   The app will attempt to recognize text from the camera stream.
    *   Recognized text will automatically appear in the "Original Text" field.

3.  **Automatic Translation:**
    *   Once text appears in the "Original Text" field (and is at least 3 characters long), it will be automatically translated into the target language (e.g., Spanish).
    *   The translation will appear in the "Translated Text" field. You may see a "Translating..." indicator.

    *(Placeholder for: Screenshot of Camera View with live OCR, original text, and translated text fields populated)*
    `![Live OCR and Translation View](./assets/screengrabs/screen2.jpg)`

### 3. Manual Text Entry & Translation

If you are not in the camera view, or if you want to type text:

1.  Ensure you are in the "capture" mode (usually by tapping the camera icon to reveal the text fields if they are hidden).
2.  **Type Text:** Enter or paste text into the "Original Text" field.
3.  **Automatic Translation:** As you type (and the text is at least 3 characters long), it will be automatically translated and shown in the "Translated Text" field.

### 4. Capturing a Translation

Once you are satisfied with the original and translated text:

1.  Click the **"Capture Translation"** button.
2.  This will save the current pair to your list of translations.
3.  The camera view might close, or the fields might clear, returning you to the list of saved translations or ready for a new capture.


### 5. Viewing Saved Translations

When the camera view is not active, the main screen will display a list of all your captured translations.

*   Each item will show the original text, the translated text, and the language code.

    *(Placeholder for: Screenshot of Capture Translation button)*
    `![Capture Translation Button](./assets/screengrabs/screen3.jpg)`
