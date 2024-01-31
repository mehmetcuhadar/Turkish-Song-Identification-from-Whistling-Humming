from flask import Flask, request, jsonify
import librosa
import numpy as np
import crepe
from sklearn.metrics.pairwise import cosine_similarity
import os
import soundfile as sf

feature_dic = dict(np.load('dataset.npz'))

app = Flask(__name__)

def process_data_function(audio, sample_rate):
    print(len(audio)/sample_rate)
    test_frames = []
    frame_samples = 800
    overlap_samples = 790
    start_sample = 0
    time, frequency, confidence, activation = crepe.predict(audio, sample_rate, viterbi=True, model_capacity="medium")

    while start_sample + frame_samples < len(frequency):
        end_sample = start_sample + frame_samples
        frame = frequency[start_sample:end_sample]
        test_frames.append(frame)
        start_sample += frame_samples - overlap_samples

    test_frames = np.array(test_frames)

    # Calculate similarities and store in a dictionary
    sim_dict_2 = {}
    freq_dict = {}
    for key in feature_dic.keys():
        sim_dict_2[key] = []
        freq_dict[key] = 0
        
    max_items = {}

    for frame in test_frames:
        similarity_dic = {}
        for key, value in feature_dic.items():
            if len(value) == 0:
                continue
            similarity = cosine_similarity([frame], value)
            most_similar_index = np.argmax(similarity[0])
            similarity_dic[key] = similarity[0][most_similar_index]
            sim_dict_2[key].append(similarity[0][most_similar_index])
        data_dict = similarity_dic

        sorted_items = sorted(data_dict.items(), key=lambda x: x[1], reverse = True)

        if sorted_items[0][0] not in list(max_items.keys()):
            max_items[sorted_items[0][0]] = 1
        else:
            max_items[sorted_items[0][0]] += 1

        freq_dict[sorted_items[0][0]] += 5
        freq_dict[sorted_items[1][0]] += 3
        freq_dict[sorted_items[2][0]] += 1

        for element in sorted_items[3:]:
            freq_dict[element[0]] += 0.5

        for key, value in sorted_items[:3]:
            print(f"Key: {key}, Value: {value}")

    # Calculate average similarities
    for key in sim_dict_2.keys():
        sim_dict_2[key] = np.mean(sim_dict_2[key])

    data_dict = sim_dict_2

    # Sort and get the top keys
    sorted_items = sorted(sim_dict_2.items(), key=lambda x: x[1], reverse=True)
    
    top_keys = [key for key, value in sorted_items[:5]]
    top_five = [key for key,value in sorted_items[:5]]
    
    for key, value in max_items.items():
        if value >= 2 and key in top_five and key != sorted_items[0][0]:
            ind = top_five.index(key)
            if ind == 1:
                continue
            temp = top_five[ind - 1]
            top_five[ind - 1] = top_five[ind]
            top_five[ind] = temp

        elif value >=2 and key not in top_five:
            top_five[4] = key
    result_dic = {}

    for el in top_five:
        result_dic[el] = freq_dict[el]
        
    sorted_items = sorted(result_dic.items(), key=lambda x: x[1], reverse = True)

    result_arr = []

    total_sum = sum(result_dic.values())

    for el in sorted_items[:5]:
        result_arr.append(el[0] + "%" + "{:.1f}".format(result_dic[el[0]]/total_sum * 100))

    return result_arr


@app.route('/', methods=['POST'])
def get_keys():
    # Replace this with the logic you want to execute
    try:
        data = request.json.get('data', [])
        # Process the received data as needed
        audio = []
        for frame in data:
            for sample in frame:
                audio.append(sample)

        max_abs = np.max(np.abs(audio))
        audio = audio / max_abs if max_abs > 0 else audio
        sf.write('stereo_file.wav', audio, 44100, 'PCM_16')
        audio, sample_rate = librosa.load("stereo_file.wav")
        print(sample_rate)
        result = process_data_function(np.array(audio), sample_rate)
        return jsonify(result)
    except Exception as e:
        return jsonify({'error': str(e)}), 500


if __name__ == "__main__":
    app.run(debug=False, host="0.0.0.0", port=int(os.environ.get("PORT", 9000)))
