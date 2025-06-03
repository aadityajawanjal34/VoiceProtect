import numpy as np
import librosa
import tensorflow as tf
import os
import sys

try:
    sys.stdout.reconfigure(encoding='utf-8')
except AttributeError:
    sys.stdout = open(sys.stdout.fileno(), mode='w', encoding='utf-8', buffering=1)

def extract_mfcc(audio_path):
    try:
        print(f"Loading audio from: {audio_path}")
        y, sr = librosa.load(audio_path, sr=16000)
        print(f"Audio loaded | Length: {len(y)/sr:.2f} sec | Sample Rate: {sr}")

        print("Extracting MFCC features...")
        mfcc = librosa.feature.mfcc(y=y, sr=sr, n_mfcc=40, n_fft=1024, hop_length=256)
        print(f"Original MFCC shape: {mfcc.shape}")

        if mfcc.shape[1] < 128:
            pad_width = 128 - mfcc.shape[1]
            print(f"MFCC too short, padding with {pad_width} frames")
            mfcc = np.pad(mfcc, ((0, 0), (0, pad_width)), mode='constant')
        else:
            mfcc = mfcc[:, :128]
        print(f"MFCC shape after padding/truncating: {mfcc.shape}")

        mfcc_input = mfcc[np.newaxis, ..., np.newaxis]
        print(f"Final MFCC input shape: {mfcc_input.shape}\n")
        return mfcc_input

    except Exception as e:
        print(f"Error in extract_mfcc: {e}")
        raise

def predict_deepfake(model_path, audio_path):
    print("Starting MFCC-based prediction pipeline...")

    if not os.path.exists(model_path):
        print(f"Model not found at: {model_path}")
        return
    if not os.path.exists(audio_path):
        print(f"Audio file not found at: {audio_path}")
        return

    try:
        print(f"Model path: {os.path.abspath(model_path)}")
        print(f"Verifying file: {os.path.abspath(audio_path)} | Exists? {'Yes' if os.path.exists(audio_path) else 'No'}")

        print("Loading model...")
        model = tf.keras.models.load_model(model_path)
        print("Model loaded successfully.\n")

        print("Extracting MFCC from audio...")
        mfcc_input = extract_mfcc(audio_path)
        print("Predicting...")
        prediction = model.predict(mfcc_input)
        confidence_score = prediction[0][0]

        if confidence_score < 0.50 or confidence_score > 0.96:
            predicted_class = "Real"
        else:
            predicted_class = "Deepfake"

        print(f"Prediction Result: {predicted_class}")
        print(f"Confidence Score: {confidence_score:.4f}")

        return predicted_class

    except Exception as e:
        print(f"Error during prediction: {e}")
        raise

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Usage: python mfcc_implementation.py <audio_path>")
        sys.exit(1)

    audio_path = sys.argv[1]
    model_path = "mfcc_cnn_model.h5"
    result = predict_deepfake(model_path, audio_path)
    print(f"\nFinal Result: {result}")
