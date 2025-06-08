#!/bin/bash

# AWS S3 Bucket Deletion Script (Bash Version)

confirm() {
    while true; do
        read -p "$1 (y/n): " response
        case "$response" in
            [yY]|[yY][eE][sS]) return 0 ;;
            [nN]|[nN][oO]) return 1 ;;
            *) echo "Please enter 'y' or 'n'" ;;
        esac
    done
}

delete_s3_bucket() {
    local bucket_name="$1"
    
    # Verify bucket exists
    if ! aws s3api head-bucket --bucket "$bucket_name" >/dev/null 2>&1; then
        echo "Error: Bucket '$bucket_name' does not exist or you don't have permission to access it."
        return 1
    fi
    
    echo -e "\nStarting deletion process for bucket: $bucket_name"
    
    # Step 1: Delete all objects
    echo -e "\nListing objects in the bucket..."
    objects=$(aws s3api list-objects --bucket "$bucket_name" --query 'Contents[].Key' --output text 2>/dev/null)
    
    if [ -n "$objects" ]; then
        object_count=$(echo "$objects" | wc -w)
        echo "Found $object_count objects in the bucket:"
        echo "$objects" | head -n 5 | nl -v1
        [ "$object_count" -gt 5 ] && echo "... and $((object_count-5)) more"
        
        if confirm "Are you sure you want to delete ALL $object_count objects?"; then
            echo "Deleting objects..."
            aws s3 rm "s3://$bucket_name/" --recursive
            echo "All objects deleted successfully."
        else
            echo "Aborting deletion."
            return 1
        fi
    else
        echo "No objects found in the bucket."
    fi
    
    # Step 2: Delete all object versions (if versioning enabled)
    echo -e "\nChecking for object versions..."
    versions=$(aws s3api list-object-versions --bucket "$bucket_name" \
              --query 'Versions[].{Key:Key,VersionId:VersionId}' --output text 2>/dev/null)
    
    if [ -n "$versions" ]; then
        version_count=$(echo "$versions" | wc -l)
        echo "Found $version_count object versions in the bucket:"
        echo "$versions" | head -n 5 | nl -v1
        [ "$version_count" -gt 5 ] && echo "... and $((version_count-5)) more"
        
        if confirm "Are you sure you want to delete ALL $version_count object versions?"; then
            echo "Deleting object versions..."
            aws s3api delete-objects-v2 --bucket "$bucket_name" --delete \
                "$(aws s3api list-object-versions --bucket "$bucket_name" \
                --query '{Objects: Versions[].{Key:Key, VersionId: VersionId}}')"
            echo "All object versions deleted successfully."
        else
            echo "Aborting deletion."
            return 1
        fi
    else
        echo "No object versions found in the bucket."
    fi
    
    # Step 3: Delete all delete markers (if any)
    echo -e "\nChecking for delete markers..."
    delete_markers=$(aws s3api list-object-versions --bucket "$bucket_name" \
                   --query 'DeleteMarkers[].{Key:Key,VersionId:VersionId}' --output text 2>/dev/null)
    
    if [ -n "$delete_markers" ]; then
        marker_count=$(echo "$delete_markers" | wc -l)
        echo "Found $marker_count delete markers in the bucket:"
        echo "$delete_markers" | head -n 5 | nl -v1
        [ "$marker_count" -gt 5 ] && echo "... and $((marker_count-5)) more"
        
        if confirm "Are you sure you want to delete ALL $marker_count delete markers?"; then
            echo "Deleting delete markers..."
            aws s3api delete-objects --bucket "$bucket_name" --delete \
                "$(aws s3api list-object-versions --bucket "$bucket_name" \
                --query '{Objects: DeleteMarkers[].{Key:Key, VersionId: VersionId}}')"
            echo "All delete markers deleted successfully."
        else
            echo "Aborting deletion."
            return 1
        fi
    else
        echo "No delete markers found in the bucket."
    fi
    
    # Final confirmation
    if confirm "ARE YOU ABSOLUTELY SURE YOU WANT TO DELETE THE ENTIRE BUCKET '$bucket_name'?"; then
        echo "Deleting the bucket..."
        aws s3api delete-bucket --bucket "$bucket_name"
        echo "Bucket '$bucket_name' deleted successfully!"
        return 0
    else
        echo "Aborting bucket deletion."
        return 1
    fi
}

# Main execution
echo "AWS S3 Bucket Deletion Script"
echo "============================="

if [ $# -ge 1 ]; then
    bucket_name="$1"
else
    read -p "Enter the name of the S3 bucket to delete: " bucket_name
fi

if [ -z "$bucket_name" ]; then
    echo "Error: Bucket name cannot be empty."
    exit 1
fi

delete_s3_bucket "$bucket_name"
