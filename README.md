# Mobile-Medi

## 🚀 How to Run the App Locally

If you are testing this app on a physical phone with the local backend, **you must update the IP address in the code** before running the app. 

### Steps for Developers:

1. **Connect to the same Wi-Fi:** Ensure your physical phone and your laptop are connected to the exact same Wi-Fi network.
2. **Find your laptop's IP address:**
   - **Windows:** Open Command Prompt, type `ipconfig`, and look for the `IPv4 Address` (e.g., `192.168.1.5`).
   - **Mac:** Open Terminal, type `ipconfig getifaddr en0`, or check System Settings > Network.
3. **Update the code:** 
   Open `lib/utils/constants.dart` and find this line (around line 18):
   ```dart
   static const String webBackendUrl = 'http://10.41.143.152:5000';
   ```
   Replace `10.41.143.152` with your laptop's current IP address.
4. **Run the app:** 
   ```bash
   flutter run
   ```

> ⚠️ **IMPORTANT GITHUB RULE:** Please DO NOT commit your personal IP address to GitHub! When you are committing your code, make sure you uncheck/discard your changes to `constants.dart` so you don't overwrite the IP address for everyone else.
