# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import os
import numpy as np
import tifffile as tf
import gc

def slice_saver(folder_path):
    # Define the output folder based on the input folder path
    output_folder = f"{folder_path}_MaxP"

    # Create the output folder if it doesn't exist
    os.makedirs(output_folder, exist_ok=True)

    # Get a list of all OME TIFF files in the folder
    tiff_files = [file for file in os.listdir(folder_path) if file.endswith('.ome.tif')]

    # Process each OME TIFF file
    for file_i in tiff_files:
        # Load the TIFF image
        image = tf.imread(os.path.join(folder_path, file))
        print(f'Working on {file}')

    	for i in range(image.shape[0]):
        	# Convert list of max projections to a numpy array
        	im_array = np.array(image[i,:,:])

        	# Convert to an appropriate data type (e.g., uint16 or uint8)
        	im_array = im_array.astype(np.uint16)

        	# Save the output image to the output folder
        	file_name = f'slice_{i}_{file_name}'
        	output_filename = os.path.join(output_folder, file_name)
        	tf.imwrite(output_filename, im_array, imagej=True)

        print(f"Saved {output_filename}")

        # Free RAM for next large image
        image = None
        max_projections = None
        gc.collect()


# Parent directory where the folders are located
parent_directory = '/media/sam/6BB441236CDA87E7/October2023_Gerbil/T123_giant/work/'

# Iterate over each folder in the parent directory
for folder in os.listdir(parent_directory):
    folder_path = os.path.join(parent_directory, folder)
    if os.path.isdir(folder_path):
        print(f"Processing folder: {folder_path}")
        slice_saver(folder_path)
