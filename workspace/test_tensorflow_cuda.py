import tensorflow as tf

# check if GPU is used
print(f'Tensorflow version: {tf.__version__}')
print(f'Tensorflow built with CUDA support: {tf.test.is_built_with_cuda()}')

# if cuda, print cuda version
if tf.test.is_built_with_cuda():
    print(f'Tensorflow CUDA version: {tf.sysconfig.get_build_info()["cuda_version"]}')
    print(f'Tensorflow CUDNN version: {tf.sysconfig.get_build_info()["cudnn_version"]}')

print(f'Is GPU available: {len(tf.config.list_physical_devices("GPU")) > 0}')
print(f'List of physical devices: {tf.config.list_physical_devices()}' )
print(f'List of logical devices: {tf.config.list_logical_devices()}')
print(f'GPU available: {tf.config.list_physical_devices("GPU")}')

# if gpu available, print its name
gpu_devices = tf.config.list_physical_devices('GPU')
if len(gpu_devices) > 0:
    gpu_details = tf.config.experimental.get_device_details(gpu_devices[0])
    print(f'GPU: {gpu_details}')
