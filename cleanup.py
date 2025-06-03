import os

def cleanup_files(file_list):
    """
    Deletes all files specified in file_list.
    Ignores files that do not exist.
    
    :param file_list: List of file paths to delete.
    """
    for file_path in file_list:
        if file_path and os.path.exists(file_path):
            try:
                os.remove(file_path)
                print(f"Cleaned up file: {file_path}")
            except Exception as e:
                print(f"Failed to remove {file_path}: {e}")
