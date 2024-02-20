import os
import numpy as np
import tifffile as tf
import gc

def compute_z_projection(folder_path, output_folder):
    # Create the output folder if it doesn't exist
    os.makedirs(output_folder, exist_ok=True)

    # Get a list of all TIFF files in the folder
    tiff_files = [file for file in os.listdir(folder_path) if file.endswith('.tiff')]

    # Process each TIFF file
    for file in tiff_files:
        
        # Load the TIFF image
        image = tf.imread(os.path.join(folder_path, file))
        print(f'Working on {file}')

         # Compute the maximum intensity projection along the z-axis
        z_projection = np.array([np.max(image[channel, :, :,:], axis=0) for channel in range(image.shape[0])])
        print('Max Projection computed')

        # Save the output image to the output folder
        output_filename = os.path.join(output_folder, file)
        tf.imwrite(output_filename, z_projection)

        print(f"Saved {output_filename}")

        # Free RAM for next large image
        image = None
        z_projection = None
        gc.collect()

# Example usage
folder_path = '/media/sam/SamHDD/M2/T123_052023'
output_folder = '/media/sam/SamHDD/M2/MaxP'

compute_z_projection(folder_path, output_folder)
