import librosa
import librosa.display
import numpy as np
import os
import pandas as pd
import crepe

# Process audio files in a folder
folder = "path/to/music/folder"
feature_dic = {}

# Iterate through subfolders
for folder_name in os.listdir(folder):
    folder_path = os.path.join(folder, folder_name)
    
    if os.path.isdir(folder_path):
        # Iterate through audio files in the subfolder
        print(sorted(feature_dic.keys()))
        for filename in os.listdir(folder_path):
            # Create a key in the feature_dic with the folder's name
            feature_dic[folder_name + " " +filename] = []
            audio_folder = os.path.join(folder_path, filename)
            print(audio_folder)
            for audio_file in os.listdir(audio_folder):
                path = os.path.join(audio_folder, audio_file)
                audio, sample_rate = librosa.load(path)
                
                # Split the audio into frames with overlap
                frames = []
                frame_samples = 800
                overlap_samples = 780
                start_sample = 0
                print(filename)
                time, frequency, confidence, activation = crepe.predict(audio, sample_rate, viterbi=True, model_capacity="medium")

                while start_sample + frame_samples < len(frequency):
                    end_sample = start_sample + frame_samples
                    frame = frequency[start_sample:end_sample]
                    #frames.append(frame)
                    start_sample += (frame_samples - overlap_samples)
                    #frames = np.array(frames)
                    feature_dic[folder_name + " " +filename].append(frame)
                
#feature_dic = {key: np.concatenate(value) for key, value in feature_dic.items()}

# Save the feature_dic
np.savez('dataset.npz', **feature_dic)