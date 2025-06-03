# 🎙️ VoiceProtect: Deepfake Audio Detector

VoiceProtect is a mobile-integrated system designed to detect **AI-generated (deepfake) audio** in recorded phone calls. Leveraging cutting-edge **deep learning**, **speaker diarization**, and **noise suppression**, this project empowers individuals to identify fraudulent audio communications using a lightweight Android app.

---

## 📱 Features

- 🔍 Detects deepfake audio using a **CNN model trained on MFCC features**
- 🔇 Removes background noise using **Demucs**
- 🧠 Separates voices using **PyAnnote speaker diarization**
- 🔐 Communicates securely with a **Flask backend** via HTTPS tunnel (Ngrok)
- 📈 Tested on the **ASVspoof 2021** dataset with added real-world noise
- 📲 Deployed via an Android **Flutter app** for call recording and inference

---

## 🛠️ Tech Stack

| Layer                 | Technologies Used                     |
| --------------------- | ------------------------------------- |
| **Frontend (Mobile)** | Flutter                               |
| **Backend**           | Python, Flask                         |
| **ML/DL Libraries**   | TensorFlow, PyAnnote, Librosa, Demucs |
| **Deployment**        | Ngrok (for secure tunneling)          |
| **Dataset**           | ASVspoof 2021 + ESC-50 (for noise)    |

---

## 🧪 Model Architecture

- **MFCC-based CNN**:

  - Input: 2D MFCC feature maps
  - Layers: Conv2D → MaxPooling → BatchNorm → GlobalAvgPooling → Dense
  - Output: Binary classification (Bonafide vs. Spoof)

- **Denoising**: Demucs (U-Net with LSTM bottleneck)
- **Speaker Diarization**: PyAnnote’s pre-trained model

## 🚀 Getting Started

### 1. Clone the repository

```bash
git clone https://github.com/aadityajawanjal34/VoiceProtect.git
cd VoiceProtect
```

### 2. Setup Python environment

```bash
pip install -r requirements.txt
```

### 3. Configure Hugging Face Token

```bash
backend/diarization.py
# HUGGINGFACE_TOKEN = "your_token_here"
```

### 4. Launch ngrok

```bash
cd backend
./ngrok http 5000
```

### 5. Launch Flask backend in new terminal

```bash
python app.py
```

### 6. Run the Flutter app

```bash
cd voiceprotectfrontend
flutter pub get
flutter run lib/main.dart
```

---

## 🧠 Dataset Details

- **ASVspoof 2021 DF**: 13,131 labeled samples (bonafide & spoofed), with various codecs
- **ESC-50**: Used to augment data with real-world noise (e.g., traffic, café sounds)

---

## 📊 Performance Metrics

| Condition            | Accuracy | Observations                              |
| -------------------- | -------- | ----------------------------------------- |
| Clean audio          | 93.0%    | High precision and low false positives    |
| Noisy audio          | 83.5%    | Accuracy dropped due to background noise  |
| Denoised with Demucs | 91.8%    | Accuracy recovered, fewer false positives |

---

## 🎯 Use Cases

- Detect AI-generated voices in suspicious calls
- Protect individuals from voice-based financial scams
- Improve trust in voice communication

---

## 📚 References

- [ASVspoof 2021 Dataset](https://www.asvspoof.org)
- [Demucs](https://github.com/facebookresearch/demucs)
- [PyAnnote-audio](https://github.com/pyannote/pyannote-audio)
- [ESC-50](https://github.com/karoldvl/ESC-50)

---

## 📌 License

This project is part of a final year B.Tech academic curriculum. For extended use, research collaboration, or commercial adaptation, please contact the authors.
