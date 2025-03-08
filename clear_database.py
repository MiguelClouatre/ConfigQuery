"""
Script to clear the ChromaDB database and start fresh.
"""
import chromadb
import config
import os
import shutil

def clear_chroma_database():
    """
    Delete and recreate the ChromaDB database.
    """
    print("Clearing ChromaDB database...")
    
    # Method 1: Delete specific collection
    try:
        client = chromadb.PersistentClient(path=config.CHROMA_DB_PATH)
        collection_name = config.CHROMA_COLLECTION_NAME
        
        # Check if collection exists before deleting
        collections = client.list_collections()
        collection_exists = any(c.name == collection_name for c in collections)
        
        if collection_exists:
            print(f"Deleting collection: {collection_name}")
            client.delete_collection(collection_name)
            print(f"Collection '{collection_name}' deleted.")
        else:
            print(f"Collection '{collection_name}' not found.")
        
        # Recreate the collection
        print(f"Creating new collection: {collection_name}")
        client.create_collection(collection_name)
        print(f"Collection '{collection_name}' created.")
        
    except Exception as e:
        print(f"Error with collection method: {e}")
        
        # Method 2: Delete the entire database directory
        try:
            print("Attempting to delete the entire database directory...")
            
            # Close any connections
            client = None
            
            # Force delete the directory
            db_path = config.CHROMA_DB_PATH
            if os.path.exists(db_path):
                shutil.rmtree(db_path)
                print(f"Database directory '{db_path}' deleted.")
            
            # Recreate the directory structure
            os.makedirs(db_path, exist_ok=True)
            
            # Create a new client and collection
            client = chromadb.PersistentClient(path=db_path)
            client.create_collection(config.CHROMA_COLLECTION_NAME)
            print(f"New collection '{config.CHROMA_COLLECTION_NAME}' created.")
            
        except Exception as e2:
            print(f"Error with directory method: {e2}")
            print("Failed to clear database. Please manually delete the database directory.")
            return False
    
    print("Database cleared successfully!")
    return True

if __name__ == "__main__":
    # Ask for confirmation
    print("WARNING: This will delete all documents in your ChromaDB database.")
    response = input("Are you sure you want to proceed? (y/n): ")
    
    if response.lower() == 'y':
        success = clear_chroma_database()
        if success:
            print("Database reset complete. You can now add new documents.")
        else:
            print("Database reset failed.")
    else:
        print("Operation cancelled.")
