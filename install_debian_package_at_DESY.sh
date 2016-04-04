#!/bin/bash
#
# This script is only intendet for internal use at DESY. It is created because
# automated generation with CMake is more convenient and easier to maintain
# than reverse-engeneering the package names using 'ls', 'grep' etc.
# In addition it can serve as a template for other debian installations.
#
# Trying to execute this, even at DESY, will probably fail due to a lack of
# priviliges. This script is intendet to be used by MTCA4U maintainers at DESY
# only.
#
# Run 'make debian_package" before you execute this script.

DEBIAN_CODENAME=`lsb_release -c | sed "{s/Codename:\s*//}"`
PACKAGE_FILES_WILDCARDS="pcieuni-dkms*.deb pcieuni-dkms*.changes"
DEB_FILES_WILDCARDS="pcieuni-dkms*.deb"

cd debian_package

# Check that there are debian packages and return an error if not
ls *.deb > /dev/null
if [ $? -ne 0 ]; then
    echo No debian packages found. Run \'make debian_package\' first.
    exit 1
fi

# Step 1: Remove an older version of the package
# -- from the nfs archive
(cd /home/debian/${DEBIAN_CODENAME}/stable; mv ${PACKAGE_FILES_WILDCARDS} ../old)
# -- from the actual repository
for REPO in intern pub; do
    ssh doocspkgs sudo -H reprepro --waitforlock 2 -Vb \
	/export/reprepro/${REPO}/doocs remove ${DEBIAN_CODENAME} pcieuni-dkms
done

# Step 2: Set the correct file privileges
chown :flash ${PACKAGE_FILES_WILDCARDS}
chmod 664 ${PACKAGE_FILES_WILDCARDS}
# -- and copy the files to the nfs archive
cp ${PACKAGE_FILES_WILDCARDS} /home/debian/${DEBIAN_CODENAME}/stable

# Step 3: Install to the repository
for REPO in intern pub; do
    for FILE in ${DEB_FILES_WILDCARDS}; do
	ssh doocspkgs sudo -H reprepro --waitforlock 2 -Vb \
	    /export/reprepro/${REPO}/doocs includedeb ${DEBIAN_CODENAME} \
	    /home/debian/${DEBIAN_CODENAME}/stable/${FILE}
   done
done
