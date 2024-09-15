FROM tensorflow/tensorflow:latest

# Install Node.js
RUN apt-get update && apt-get install -y nodejs

# Install TensorFlow.js and other useful utils
RUN pip install tensorflowjs \
	onnx \
	onnx-tf \
	ultralytics
