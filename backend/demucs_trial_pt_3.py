import subprocess
import sys
from pathlib import Path
import shutil
import time

def verify_demucs_installation():
    try:
        import demucs
        print(f" Demucs version: {demucs.__version__}")
        return True
    except ImportError:
        print(" Demucs not installed in this environment.")
        return False

def get_device():
    try:
        import torch
        return "cuda" if torch.cuda.is_available() else "cpu"
    except ImportError:
        print(" Torch not installed. Defaulting to CPU.")
        return "cpu"

def denoise_audio(input_file: str, output_dir: str, model: str = "htdemucs") -> str:
    if not verify_demucs_installation():
        return ""

    input_path = Path(input_file)
    output_path = Path(output_dir)
    output_path.mkdir(parents=True, exist_ok=True)

    if not input_path.exists():
        print(f" Input file not found: {input_path}")
        return ""

    start_time = time.time()

    device = get_device()
    print(f" Using device: {device.upper()}")

    cmd = [
        sys.executable, "-m", "demucs.separate",
        "-n", model,
        "-o", str(output_path),
        "--device", device,
        "--shifts", "1",
        "--float32",
        "--two-stems=vocals",
        str(input_path)
    ]

    try:
        print(f"\n Running Demucs on: {input_path.name}")
        subprocess.run(cmd, check=True, capture_output=True, text=True)

        temp_output_path = output_path / model / input_path.stem
        vocals_file = temp_output_path / "vocals.wav"
        final_output_file = output_path / f"{input_path.stem}_denoised.wav"

        if vocals_file.exists():
            vocals_file.replace(final_output_file)
            print(f" Denoised file saved: {final_output_file}")
        else:
            print(" Vocals file not found.")
            return ""

        shutil.rmtree(output_path / model, ignore_errors=True)
        print(" Cleaned intermediate files.")

    except subprocess.CalledProcessError as e:
        print(f" Demucs error: {e.stderr}")
        return ""
    except Exception as e:
        print(f" Unexpected error: {e}")
        return ""

    print(f" Demucs processing time: {time.time() - start_time:.2f} seconds")
    return str(final_output_file)
