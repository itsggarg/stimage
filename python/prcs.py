from flask import Flask, request, jsonify, send_from_directory
from flask_cors import CORS
import cv2
import numpy as np
import os
from werkzeug.utils import secure_filename
import base64
import binascii
import datetime
from facenet_pytorch import MTCNN
import cv2
from PIL import Image
import numpy as np
import torch

app = Flask(__name__)
CORS(app)

UPLOAD_FOLDER = 'uploads'
STITCHED_FOLDER = 'stitched'
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
os.makedirs(STITCHED_FOLDER, exist_ok=True)

# Configure Flask to serve static files from the stitched folder
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['STITCHED_FOLDER'] = STITCHED_FOLDER


@app.route('/stitched/<path:filename>')
def serve_stitched_image(filename):
    return send_from_directory(STITCHED_FOLDER, filename)


def stitch_images(images):
    stitcher = cv2.Stitcher_create()
    if len(images) < 2:
        raise Exception('At least two images are required for stitching')

    status, stitched_image = stitcher.stitch(images)

    if status == cv2.Stitcher_OK:
        return stitched_image
    elif status == cv2.Stitcher_ERR_NEED_MORE_IMGS:
        raise Exception('Not enough images provided')
    elif status == cv2.Stitcher_ERR_NOT_ENOUGH_FEATURES:
        raise Exception('Not enough features found')
    elif status == cv2.Stitcher_ERR_HOMOGRAPHY_EST_FAIL:
        raise Exception('Homography estimation failed')
    elif status == cv2.Stitcher_ERR_CAMERA_PARAMS_ADJUST_FAIL:
        raise Exception('Camera parameters adjustment failed')
    else:
        raise Exception('Stitching failed with unknown error')


@app.route('/stitch', methods=['POST'])
def stitch():
    app.logger.info("Received request to stitch images.")

    course_code = request.json.get('course_code')
    classroom_number = request.json.get('classroom_number')
    images_str = request.json.get('images')

    if images_str:
        images = []
        image_strings = images_str

        for image_str in image_strings:
            try:
                # Decode the base64 string for each image
                image_bytes = base64.b64decode(image_str, validate=False)
                # Decode the bytes to OpenCV image
                image = cv2.imdecode(
                    np.frombuffer(image_bytes, np.uint8), cv2.IMREAD_COLOR
                )

                if image is not None:
                    images.append(image)
                else:
                    return jsonify({'error': f'Failed to decode image'}), 500

            except Exception as e:
                return jsonify({'error': f'Failed to decode image: {e}'}), 500

        if len(images) < 2:
            app.logger.error("Less than two images provided.")
            return jsonify({'error': 'At least two images are required'}), 400

        try:
            app.logger.info("Stitching images.")
            stitched_image = stitch_images(images)
            if stitched_image is not None:
                # Perform face detection on the stitched image
                face_count = count_faces_mtcnn(stitched_image)
                # Base64 encode for transferring the image through network
                _, encoded_image = cv2.imencode('.jpg', stitched_image)
                stitched_image_base64 = base64.b64encode(encoded_image).decode(
                    'utf-8'
                )

                # Save the stitched image to the server with a filename
                filename = f'{course_code}_{classroom_number}_{
                    datetime.datetime.now().strftime("%Y%m%d%H%M%S")}.jpg'
                image_path = os.path.join(
                    app.config['STITCHED_FOLDER'], filename)
                cv2.imwrite(image_path, stitched_image)

                return jsonify(
                    {
                        'stitched_image': stitched_image_base64,
                        'face_count': face_count,
                        'image_path': image_path
                    }
                )
            else:
                return jsonify({'error': 'Error stitching images'}), 500
        except Exception as e:
            app.logger.error(f"Error occurred: {e}")
            return jsonify({'error': str(e)}), 500

    else:
        app.logger.error("No images provided.")
        return jsonify({'error': 'No images provided'}), 400


def detect_faces(image):
    face_cascade = cv2.CascadeClassifier(
        cv2.data.haarcascades + 'haarcascade_frontalface_default.xml'
    )
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    faces = face_cascade.detectMultiScale(gray, 1.1, 4)
    return len(faces)


def count_faces_mtcnn(img):
    # Load the MTCNN model
    mtcnn = MTCNN(
        keep_all=True, device='cuda' if torch.cuda.is_available() else 'cpu')

    # Read and convert the image
    img_np = np.array(img)

    # Detect faces
    boxes, probs = mtcnn.detect(img_np, landmarks=False)

    # Draw bounding boxes on the image
    if boxes is not None:
        num_faces = len(boxes)
        for box in boxes:
            cv2.rectangle(img_np, (int(box[0]), int(box[1])), (int(
                box[2]), int(box[3])), (0, 255, 0), 2)
        # print(f"Number of faces detected: {num_faces}")
    else:
        # print("No faces detected.")
        num_faces = 0

    # Convert image to BGR format for display
    # img_np_bgr = cv2.cvtColor(img_np, cv2.COLOR_RGB2BGR)

    # Display the output image
    # cv2.imshow(img_np_bgr)
    return num_faces


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=5000, debug=True)
