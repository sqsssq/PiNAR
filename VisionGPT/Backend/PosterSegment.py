'''
Description: Extract text and positions from a poster image using OCR
Author: Qing Shi
Date: 2025-05-08 16:14:50
LastEditors: Qing Shi
LastEditTime: 2025-05-11 20:20:28
'''

import cv2
import pytesseract
from pytesseract import Output

def extract_text_and_positions(image_path):
    """
    Extract text and their positions from an image using Tesseract OCR.

    Args:
        image_path (str): Path to the input image.

    Returns:
        list: A list of dictionaries containing text and bounding box information.
    """
    # Load the image
    image = cv2.imread(image_path)
    
    # Convert the image to grayscale for better OCR accuracy
    gray = cv2.cvtColor(image, cv2.COLOR_BGR2GRAY)
    
    # Perform OCR using Tesseract
    custom_config = r'--oem 3 --psm 6'  # OCR Engine Mode and Page Segmentation Mode
    data = pytesseract.image_to_data(gray, output_type=Output.DICT, config=custom_config)
    
    # Parse the OCR results
    results = []
    for i in range(len(data['text'])):
        if data['text'][i].strip():  # Ignore empty text
            word_info = {
                'text': data['text'][i],
                'x': data['left'][i],
                'y': data['top'][i],
                'width': data['width'][i],
                'height': data['height'][i]
            }
            results.append(word_info)
    
    return results

def visualize_results(image_path, results):
    """
    Visualize the OCR results by drawing bounding boxes and text on the image.

    Args:
        image_path (str): Path to the input image.
        results (list): OCR results containing text and bounding box information.
    """
    # Load the image
    image = cv2.imread(image_path)
    
    # Draw bounding boxes and text
    for word in results:
        x, y, width, height = word['x'], word['y'], word['width'], word['height']
        cv2.rectangle(image, (x, y), (x + width, y + height), (0, 255, 0), 2)
        cv2.putText(image, word['text'], (x, y - 10), cv2.FONT_HERSHEY_SIMPLEX, 0.5, (0, 255, 0), 1)
    
    # Display the image
    cv2.imshow("OCR Results", image)
    cv2.waitKey(0)
    cv2.destroyAllWindows()

if __name__ == "__main__":
    # Path to the input image
    image_path = "poster.jpg"  # Replace with the path to your poster image
    
    # Extract text and positions
    results = extract_text_and_positions(image_path)
    
    # Print the results
    for word in results:
        print(word)
    
    # Visualize the results (optional)
    visualize_results(image_path, results)
