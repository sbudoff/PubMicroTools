# -*- coding: utf-8 -*-
"""
Spyder Editor

This is a temporary script file.
"""

import os
import numpy as np
import tifffile as tf
import gc

def compute_z_projection(folder_path, num_channels):
    # Define the output folder based on the input folder path
    output_folder = f"{folder_path}_MaxP"

    # Create the output folder if it doesn't exist
    os.makedirs(output_folder, exist_ok=True)

    # Get a list of all OME TIFF files in the folder
    tiff_files = [file for file in os.listdir(folder_path) if file.endswith('.ome.tif')]

    # Process each OME TIFF file
    for file in tiff_files:
        # Load the TIFF image
        image = tf.imread(os.path.join(folder_path, file))
        print(f'Working on {file}')

        # Check the dimensionality of the image
        if image.ndim == 3:  # Interleaved channel and z-position
            max_projections = [np.max(image[channel::num_channels], axis=0) for channel in range(num_channels)]
        elif image.ndim == 4:  # Separate channel and z-position dimensions
            max_projections = [np.max(image[channel, :, :, :], axis=0) for channel in range(num_channels)]
        else:
            raise ValueError("Unexpected image dimensions")

        # Convert list of max projections to a numpy array
        max_projections = np.array(max_projections)

        print('Max Projection computed')

        # Convert to an appropriate data type (e.g., uint16 or uint8)
        max_projections = max_projections.astype(np.uint16)

        # Save the output image to the output folder
        output_filename = os.path.join(output_folder, file)
        tf.imwrite(output_filename, max_projections, imagej=True)

        print(f"Saved {output_filename}")

        # Free RAM for next large image
        image = None
        max_projections = None
        gc.collect()


# Parent directory where the folders are located
parent_directory = '/media/sam/6BB441236CDA87E7/October2023_Gerbil/T123_giant/work/'

# Number of channels in the images
num_channels = 3  # Adjust the number of channels as needed

# Iterate over each folder in the parent directory
for folder in os.listdir(parent_directory):
    folder_path = os.path.join(parent_directory, folder)
    if os.path.isdir(folder_path):
        print(f"Processing folder: {folder_path}")
        compute_z_projection(folder_path, num_channels)