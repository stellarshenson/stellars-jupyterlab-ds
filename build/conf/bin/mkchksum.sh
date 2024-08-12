SRCDIR=$1
TGTDIR=$(dirname $2)
TGTFILE=$2

# create dir
mkdir -p $TGTDIR 

find $SRCDIR -type f -exec sha256sum {} \; > $TGTFILE

