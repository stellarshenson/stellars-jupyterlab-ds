#!/opt/conda/bin/python

from colorama import Fore, Back, Style
import os
import sys


def coloured_text(text, colour="white", bg_colour="normal", style="normal") -> str:
    """
    returns coloured text using Colorama

    Parameters:
        text (str): The text to be printed.
        colour (str): The text colour. Default is white.
        bg_colour (str): The background colour. Default is black.
        style (str): The text style. Default is normal.

    Returns:
        None
    """
    # Map string inputs to Colorama constants
    colour_mapping = {
        "black": Fore.BLACK, "red": Fore.RED, "green": Fore.GREEN,
        "yellow": Fore.YELLOW, "blue": Fore.BLUE, "magenta": Fore.MAGENTA,
        "cyan": Fore.CYAN, "white": Fore.WHITE, "lightgreen": Fore.LIGHTGREEN_EX,
        "lightred": Fore.LIGHTRED_EX, "lightblue": Fore.LIGHTBLUE_EX,
    }
    bg_colour_mapping = {
        "black": Back.BLACK, "red": Back.RED, "green": Back.GREEN,
        "yellow": Back.YELLOW, "blue": Back.BLUE, "magenta": Back.MAGENTA,
        "cyan": Back.CYAN, "white": Back.WHITE, 'normal': Back.RESET
    }
    style_mapping = {
        "normal": Style.NORMAL, "bright": Style.BRIGHT, "dim": Style.DIM,
    }

    # Get the Colorama constants for colour, background colour, and style
    selected_colour = colour_mapping.get(colour.lower(), Fore.WHITE)
    selected_bg_colour = bg_colour_mapping.get(bg_colour.lower(), Back.BLACK)
    selected_style = style_mapping.get(style.lower(), Style.NORMAL)

    # Construct the coloured text
    coloured_text = f"{selected_style}{selected_bg_colour}{selected_colour}{text}{Style.RESET_ALL}"
    return coloured_text


def coloured_print(text, colour="white", bg_colour="normal", style="normal"):
    """
    Wrapper function for print that prints coloured text using Colorama.

    Parameters:
        text (str): The text to be printed.
        colour (str): The text colour. Default is white.
        bg_colour (str): The background colour. Default is black.
        style (str): The text style. Default is normal.

    Returns:
        None
    """
    print(coloured_text(text, colour, bg_colour, style))


def check_tensorflow():
    # only initialise tensorflow when called  (prevents segfault because of conflict with torch)
    import tensorflow as tf

    is_gpu = len(tf.config.list_physical_devices("GPU")) > 0    
    colour = 'green' if is_gpu == True else 'red'
    
    # check for tensorflow devices
    coloured_print('', colour=colour)
    coloured_print('#### Tensorflow ########################################', colour='light'+colour)
    
    # check if GPU is used
    coloured_print(f'Tensorflow version: {tf.__version__}', colour=colour)
    coloured_print(f'Tensorflow built with CUDA support: {tf.test.is_built_with_cuda()}', colour=colour)
    
    # if cuda, print cuda version
    if tf.test.is_built_with_cuda():
        coloured_print(f'Tensorflow CUDA version: {tf.sysconfig.get_build_info()["cuda_version"]}', colour=colour)
        coloured_print(f'Tensorflow CUDNN version: {tf.sysconfig.get_build_info()["cudnn_version"]}', colour=colour)
    
    # if gpu available, print its name
    gpu_devices_list = tf.config.list_physical_devices('GPU')
    coloured_print(f'Tensorflow found CUDA devices: {len(gpu_devices_list)}', colour=colour)
    if len(gpu_devices_list) > 0:
        for i in range(0, len(gpu_devices_list)):
            gpu_details = tf.config.experimental.get_device_details(gpu_devices_list[i])
            coloured_print(f'GPU {i}: {gpu_details["device_name"]}', colour=colour)
        

def check_pytorch():
    # only initialise torch when called (prevents segfault)
    import torch
    
    is_gpu = torch.cuda.device_count() > 0
    colour = 'green' if is_gpu == True else 'red'
    
    # check for torch devices
    coloured_print('', colour=colour)
    coloured_print('#### pyTorch ###########################################', colour='light'+colour)

    coloured_print(f'pyTorch version: {torch.__version__}', colour=colour)
    coloured_print(f'pyTorch built with CUDA support: {torch.cuda.is_available()}', colour=colour)
    if torch.cuda.is_available(): coloured_print(f"pyTorch CUDA version: {torch.version.cuda}", colour=colour)
    coloured_print(f'pyTorch found CUDA devices: {torch.cuda.device_count()}', colour=colour)

    if torch.cuda.device_count() > 0:
        for i in range(0, torch.cuda.device_count()):
            coloured_print(f'GPU {i}: {torch.cuda.get_device_name(i)}', colour=colour)

if __name__ == '__main__':
    # Redirect stderr to /dev/null but save orig fd
    devnull = open(os.devnull, 'w')
    devnull_fd = devnull.fileno()
    original_stderr_fd = os.dup(sys.stderr.fileno())
    os.dup2(devnull_fd, sys.stderr.fileno())

    check_pytorch() # need to call before tensorflow    
    check_tensorflow()
    print('')

    # Restore stderr
    os.dup2(original_stderr_fd, sys.stderr.fileno())
    
# EOF
