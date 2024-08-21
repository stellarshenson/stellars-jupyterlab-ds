VOLUME=$2
ARCHIVE=$1
if [[ -z $VOLUME || -z $ARCHIVE ]]; then
    echo "usage: $0 <archive file> <volume name>"
    exit 1
fi

echo "generating volume '$VOLUME' from '$ARCHIVE'"
docker run --rm -v $VOLUME:/mnt -v $(pwd):/backup busybox sh -c "cd /mnt && tar -xzvf /backup/$ARCHIVE"
