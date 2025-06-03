import numpy as np
import librosa
import tensorflow as tf
import os
import sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except AttributeError:
    sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf-8', buffering=1)

def extract_mel_spectrogram(audio_path, n_mels=128, duration=3, sr=16000):
    try:
        print(f"Loading audio from: {audio_path}")
        y, sr = librosa.load(audio_path, sr=sr, duration=duration)
        print(f"Audio loaded | Length: {len(y)/sr:.2f} sec | Sample Rate: {sr}")

        expected_len = int(duration * sr)
        if len(y) < expected_len:
            pad_width = expected_len - len(y)
            print(f"Audio too short, padding with {pad_width} samples")
            y = np.pad(y, (0, pad_width), mode='constant')

        print("Computing Mel spectrogram...")
        mel_spec = librosa.feature.melspectrogram(y=y, sr=sr, n_mels=n_mels)
        print("Converting to decibel scale...")
        mel_spec_db = librosa.power_to_db(mel_spec, ref=np.max)
        print("Fixing length to (128, 128)...")
        mel_spec_db = librosa.util.fix_length(mel_spec_db, size=128, axis=1)

        print("Mel spectrogram extracted successfully.\n")
        return mel_spec_db

    except Exception as e:
        print(f"Error in extract_mel_spectrogram: {e}")
        raise

def predict_deepfake(model_path, audio_path):
    print("Starting prediction pipeline...")

    if not os.path.exists(model_path):
        print(f"Model not found at: {model_path}")
        return
    if not os.path.exists(audio_path):
        print(f"Audio file not found at: {audio_path}")
        return

    try:
        print(f"Model path: {os.path.abspath(model_path)}")
        print(f"Verifying file: {os.path.abspath(audio_path)} | Exists? Yes")

        print("Loading model...")
        model = tf.keras.models.load_model(model_path)
        print("Model loaded successfully.\n")

        print("Extracting features from audio...")
        mel_spec = extract_mel_spectrogram(audio_path)
        print(f"Original Mel shape: {mel_spec.shape}")
        mel_spec = np.expand_dims(mel_spec, axis=[0, -1])  # Shape: (1, 128, 128, 1)
        print(f"Input shape for model: {mel_spec.shape}\n")

        print("Predicting...")
        prediction = model.predict(mel_spec)
        class_names = ["Real", "Deepfake"]
        predicted_class = class_names[int(np.round(prediction[0][0]))]

        print(f"Prediction Result: {predicted_class}")
        print(f"Confidence Score: {prediction[0][0]:.4f}")

        return predicted_class

    except Exception as e:
        print(f"Error during prediction: {e}")
        raise

# Entry point for command-line usage.
if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python mel_cnn_implementation.py <audio_path>")
        sys.exit(1)

    audio_path = sys.argv[1]
    model_path = "mel_cnn_model.h5"  # Ensure this file exists.
    result = predict_deepfake(model_path, audio_path)
    print(f"\nFinal Result: {result}")