from pydub import AudioSegment
import os

def save_speaker_segments(denoised_audio_path, segments, output_dir="speaker_outputs", silence_padding_ms=300):
    print(f"\nPreparing speaker-separated audio from: {denoised_audio_path}")
    os.makedirs(output_dir, exist_ok=True)
    audio = AudioSegment.from_wav(denoised_audio_path)

    # Resolve overlapping segments and sort by start time.
    print("Resolving overlaps...")
    timeline = []
    sorted_segments = sorted(segments, key=lambda s: s["start"])
    for seg in sorted_segments:
        timeline.append((seg["start"], seg["end"], seg["speaker"]))

    cleaned_segments = []
    last_end = 0.0
    for start, end, speaker in timeline:
        if start < last_end:
            start = last_end  # Adjust overlap.
        if end > start:
            cleaned_segments.append({"speaker": speaker, "start": round(start, 2), "end": round(end, 2)})
            last_end = end

    # Combine segments for each speaker with padding.
    speaker_audio = {}
    for segment in cleaned_segments:
        speaker = segment["speaker"]
        start_ms = int(segment["start"] * 1000)
        end_ms = int(segment["end"] * 1000)

        print(f"{speaker} → {start_ms}ms to {end_ms}ms")
        chunk = audio[start_ms:end_ms]

        if speaker not in speaker_audio:
            speaker_audio[speaker] = chunk
        else:
            speaker_audio[speaker] += AudioSegment.silent(duration=silence_padding_ms) + chunk

    output_paths = []
    for speaker, full_audio in speaker_audio.items():
        out_path = os.path.join(output_dir, f"{speaker}.wav")
        full_audio.export(out_path, format="wav")
        print(f"Exported {speaker} audio: {out_path}")
        output_paths.append(out_path)

    return output_paths
