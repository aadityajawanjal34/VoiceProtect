from pyannote.audio import Pipeline
import torch

# Load pipeline
pipeline = Pipeline.from_pretrained(
    "pyannote/speaker-diarization-3.1",
    use_auth_token="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"
)

# Send to GPU (optional)
pipeline.to(torch.device("cuda" if torch.cuda.is_available() else "cpu"))

# Run on audio file
diarization = pipeline(r"input_audio\audio_16k_7_clean_output_1.wav")

# Output RTTM format (standard diarization format)
with open("audio.rttm", "w") as f:
    diarization.write_rttm(f)

# Print speaker segments
for turn, _, speaker in diarization.itertracks(yield_label=True):
    print(f"Speaker {speaker}: {turn.start:.1f}s --> {turn.end:.1f}s")