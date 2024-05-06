import tensorflow as tf
import torch

# check for tensorflow devices
print('\n')
print('#### Tensorflow ########################################')

# check if GPU is used
print(f'Tensorflow version: {tf.__version__}')
print(f'Tensorflow built with CUDA support: {tf.test.is_built_with_cuda()}')

# if cuda, print cuda version
if tf.test.is_built_with_cuda():
    print(f'Tensorflow CUDA version: {tf.sysconfig.get_build_info()["cuda_version"]}')
    print(f'Tensorflow CUDNN version: {tf.sysconfig.get_build_info()["cudnn_version"]}')

print(f'Is GPU available: {len(tf.config.list_physical_devices("GPU")) > 0}')
# print(f'List of physical devices: {tf.config.list_physical_devices()}' )
# print(f'List of logical devices: {tf.config.list_logical_devices()}')
# print(f'GPU available: {tf.config.list_physical_devices("GPU")}')

# if gpu available, print its name
gpu_devices = tf.config.list_physical_devices('GPU')
print(f'Tensorflow found CUDA devices: {len(gpu_devices)}')
if len(gpu_devices) > 0:
    for i in range(0, len(gpu_devices)):
        gpu_details = tf.config.experimental.get_device_details(gpu_devices[i])
        print(f'GPU {i}: {gpu_details["device_name"]}')


# check for torch devices
print('\n')
print('#### Torch #############################################')

print(f'Torch built with CUDA support: {torch.cuda.is_available()}')
if torch.cuda.is_available(): print(f"Torch CUDA version: {torch.version.cuda}")
print(f'Torch found CUDA devices: {torch.cuda.device_count()}')
if torch.cuda.device_count() > 0:
    for i in range(0, torch.cuda.device_count()):
        print(f'Torch CUDA device {i}: {torch.cuda.get_device_name(i)}')

print('\n')