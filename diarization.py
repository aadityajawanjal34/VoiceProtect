from pyannote.audio import Pipeline
import torch

# Initialize the diarization pipeline using a pretrained model.
pipeline = Pipeline.from_pretrained(
    "pyannote/speaker-diarization-3.1",
    use_auth_token="insert_token_here"
)
pipeline.to(torch.device("cuda" if torch.cuda.is_available() else "cpu"))

def run_diarization(audio_path):
    print(f"\n Running speaker diarization on: {audio_path}")
    diarization = pipeline(audio_path)
    segments = []
    print("\n Diarization Results:")
    for turn, _, speaker in diarization.itertracks(yield_label=True):
        segment_info = {
            "speaker": speaker,
            "start": round(turn.start, 2),
            "end": round(turn.end, 2)
        }
        print(f" Speaker {speaker}: {turn.start:.2f}s --> {turn.end:.2f}s")
        segments.append(segment_info)
    return segments
