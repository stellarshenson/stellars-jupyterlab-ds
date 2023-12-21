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
    _consoleHandler.setFormatter(_colouredFormatter)

    if not logger.hasHandlers(): 
        logger.addHandler(_consoleHandler)

# Print iterations progress
def printProgressBar (iteration, total, prefix = '', suffix = '', decimals = 1, length = 100, fill = '█', printEnd = "\r"):
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
        print()
