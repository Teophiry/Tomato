from flask import Flask, request, render_template
import tensorflow as tf
import numpy as np
from tensorflow.keras.preprocessing.image import load_img, img_to_array

app = Flask(__name__)

# Load the trained model
model = tf.keras.models.load_model('plant_disease_model.h5')

# Class labels (update based on your dataset)
class_labels = ['Early_Blight', 'Healthy', 'Late_Blight', 'Leaf_Miner',
                'Magnesium_Deficiency', 'Nitrogen_Deficiency',
                'Potassium_Deficiency', 'Spotted_Wilt_Virus']

# Preprocess the uploaded image
def preprocess_image(image_path):
    img = load_img(image_path, target_size=(224, 224))
    img_array = img_to_array(img)
    img_array = img_array / 255.0  # Normalize
    img_array = np.expand_dims(img_array, axis=0)  # Add batch dimension
    return img_array

@app.route('/', methods=['GET', 'POST'])
def upload_image():
    if request.method == 'POST':
        if 'file' not in request.files:
            return render_template('index.html', message='No file uploaded')
        file = request.files['file']
        if file.filename == '':
            return render_template('index.html', message='No file selected')
        image_path = 'static/uploaded_image.jpg'
        file.save(image_path)
        img_array = preprocess_image(image_path)
        predictions = model.predict(img_array)
        predicted_class = class_labels[np.argmax(predictions[0])]
        confidence = np.max(predictions[0]) * 100
        return render_template('index.html',
                             prediction=predicted_class,
                             confidence=f'{confidence:.2f}%',
                             image_path=image_path)
    return render_template('index.html')

if __name__ == '__main__':
    app.run(debug=True)