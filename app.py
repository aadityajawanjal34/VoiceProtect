from flask import Flask, request, jsonify
from flask_cors import CORS  
import os
import uuid
import subprocess
import traceback

from diarization import run_diarization
from demucs_trial_pt_3 import denoise_audio
from speaker_audio_splitter import save_speaker_segments
from cleanup import cleanup_files  

app = Flask(__name__)
CORS(app)  

UPLOAD_FOLDER = 'uploads'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER

def convert_to_wav(input_path):
    if input_path.lower().endswith(".wav"):
        print(f"Already a WAV file, skipping conversion: {input_path}")
        return input_path

    output_path = os.path.splitext(input_path)[0] + ".wav"
    try:
        print(f"Converting {input_path} to WAV...")
        subprocess.run([
            "ffmpeg", "-y", "-i", input_path,
            "-ar", "16000", "-ac", "1", output_path
        ], check=True)
        print(f"Converted to WAV: {output_path}")
        return output_path
    except subprocess.CalledProcessError:
        raise Exception("FFmpeg failed to convert file.")

def classify_speakers_tf_env(audio_paths):
    results = []
    script_dir = r"D:\engg\final year\sem 8\projec\demucs_git_clone"

    print(f"\nScript directory: {script_dir}")
    print(f"Number of audio segments to process: {len(audio_paths)}")

    for path in audio_paths:
        print(f"\nChecking for deepfake in: {path}")
        try:
            abs_path = os.path.abspath(path)
            print(f"Verifying file: {abs_path} | Exists? {'Yes' if os.path.exists(abs_path) else 'No'}")

            if not os.path.exists(abs_path):
                print(f"Skipping: File not found at {abs_path}")
                results.append("FileNotFound")
                continue


            # ✅ MFCC CNN (active now)
            command = (
                f'cmd.exe /c "call tf_env\\Scripts\\activate.bat && '
                f'python mfcc_cnn_implementation.py \"{abs_path}\""'
            )

            print(f"Running command: {command}")
            print(f"Working directory: {script_dir}")

            process = subprocess.run(
                command,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True,
                encoding='utf-8',
                cwd=script_dir
            )

            stdout_output = process.stdout
            stderr_output = process.stderr

            print(f"Subprocess completed | Exit code: {process.returncode}")
            if stdout_output:
                print(f"STDOUT:\n{stdout_output}")
            if stderr_output:
                print(f"STDERR:\n{stderr_output}")

            output = stdout_output.strip() if stdout_output else "No output received"

            if "Deepfake" in output:
                results.append("Deepfake")
            elif "Real" in output:
                results.append("Real")
            else:
                print("Unexpected output, marking as Unknown")
                results.append("Unknown")

        except UnicodeDecodeError as e:
            print(f"UnicodeDecodeError: {e} | Skipping file due to decoding issues")
            results.append("DecodeError")
        except Exception as e:
            print(f"Exception occurred while running model: {e}")
            results.append("Error")

    return results

@app.route('/upload-audio', methods=['POST'])
def upload_audio():
    print("\n🔥 Incoming request to /upload-audio")
    print(f"Request headers: {request.headers}")
    print(f"Content-Type: {request.content_type}")
    print(f"Incoming files: {list(request.files.keys())}")
    print(f"Incoming form: {request.form}")

    temp_files = []

    try:
        os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)

        if 'file' not in request.files:
            print("❌ No 'file' key in uploaded files")
            return jsonify({"error": "No file part"}), 400

        file = request.files['file']
        if file.filename == '':
            print("❌ Empty filename received")
            return jsonify({"error": "No selected file"}), 400

        filename = str(uuid.uuid4()) + "_" + file.filename
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], filename)
        file.save(filepath)
        temp_files.append(filepath)
        print(f"✅ File saved: {filepath}")

        wav_path = convert_to_wav(filepath)
        if wav_path != filepath:
            temp_files.append(wav_path)

        denoised_output_dir = os.path.join(app.config['UPLOAD_FOLDER'], "denoised")
        os.makedirs(denoised_output_dir, exist_ok=True)
        denoised_path = denoise_audio(wav_path, denoised_output_dir)
        if denoised_path:
            temp_files.append(denoised_path)
        else:
            raise Exception("Denoising failed.")

        print(f"Denoised file ready: {denoised_path}")

        segments = run_diarization(denoised_path)
        speaker_files = save_speaker_segments(denoised_path, segments)
        temp_files.extend(speaker_files)

        deepfake_results = classify_speakers_tf_env(speaker_files)
        final_verdict = "Deepfake" if "Deepfake" in deepfake_results else "Real"
        confidence_score = 0.6765  # Placeholder

        result = {
            "segments": segments,
            "filename": filename,
            "speaker_audio_files": speaker_files,
            "deepfake_results_per_speaker": deepfake_results,
            "final_verdict": final_verdict,
            "confidence_score": confidence_score
        }

        response = jsonify(result)

    except Exception as e:
        traceback.print_exc()
        response = jsonify({"error": str(e)})
        response.status_code = 500
    finally:
        try:
            cleanup_files(temp_files)
        except Exception as cleanup_error:
            print(f"Cleanup error: {cleanup_error}")
    return response

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000)