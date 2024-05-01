'''
this is fancy colourful logger to use in your notebooks
you would use it by simply importing this logger into your 
project

example:

# import logger
from logger import *

# use logger
logger.info('info message')

'''


import logging
import sys

from typing import Optional, Dict
from colorama import Fore, Back, Style


class ColoredFormatter(logging.Formatter):
    """Colored log formatter."""

    def __init__(self, *args, colors: Optional[Dict[str, str]]=None, **kwargs) -> None:
        """Initialize the formatter with specified format strings."""

        super().__init__(*args, **kwargs)

        self.colors = colors if colors else {}

    def format(self, record) -> str:
        """Format the specified record as text."""

        record.color = self.colors.get(record.levelname, '')
        record.reset = Style.RESET_ALL
        record.funcColor = Fore.BLUE
        return super().format(record)


# create a logger
logger = logging.getLogger('notebook')


# initialise logger handlers (private block of code)
if True:
    logger.setLevel(logging.INFO)
    _colouredFormatter = ColoredFormatter(
        '{asctime} - {color}{levelname:5}{reset} - {funcColor}{funcName}{reset} - {message}',
        style='{', datefmt='%Y-%m-%d %H:%M:%S',
        colors={
            'DEBUG': Fore.CYAN,
            'INFO': Fore.GREEN,
            'WARNING': Fore.YELLOW,
            'ERROR': Fore.RED,
            'CRITICAL': Fore.RED + Back.WHITE + Style.BRIGHT,
        }
    )
    
    #formatter = logging.Formatter('%(asctime)s [%(levelname)s] %(name)s - %(funcName)s - %(message)s')
    _plainFormatter = logging.Formatter('%(asctime)s [%(levelname)s] %(funcName)s - %(message)s')
    _consoleHandler = logging.StreamHandler(sys.stdout)

    # enable colour formatter only if in notebook
    if 'ipykernel' in sys.modules:
        _consoleHandler.setFormatter(_colouredFormatter)
    else:
        _consoleHandler.setFormatter(_plainFormatter)

    if not logger.hasHandlers(): 
        logger.addHandler(_consoleHandler)

# Print iterations progress
def progressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 50, fill = '█', printEnd = "\r"):
    """
    Call in a loop to create terminal progress bar
    @params:
        iteration   - Required  : current iteration (Int)
        total       - Required  : total iterations (Int)
        prefix      - Optional  : prefix string (Str)
        suffix      - Optional  : suffix string (Str)
        decimals    - Optional  : positive number of decimals in percent complete (Int)
        length      - Optional  : character length of bar (Int)
        fill        - Optional  : bar fill character (Str)
        printEnd    - Optional  : end character (e.g. "\r", "\r\n") (Str)
    """
    percent = ("{0:." + str(decimals) + "f}").format(100 * (iteration / float(total)))
    filledLength = int(length * iteration // total)
    bar = fill * filledLength + '-' * (length - filledLength)
    print(f'\r{prefix} |{bar}| {percent}% {suffix}', end = printEnd)
    # Print New Line on Complete
    if iteration == total: 
        print('')


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
        "cyan": Fore.CYAN, "white": Fore.WHITE
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


class StopExecution(Exception):
    """
    by raising this exception you can quietly stop
    notebook processing

    Example:
    >>> raise StopExecution
    """
    def _render_traceback_(self):
        return []


def exit_cell():
    raise StopExecution('stopped')

# EOF
