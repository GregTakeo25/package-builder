#!/bin/bash

function error {
  echo $1
  aws sqs send-message --queue-url $SQS_QUEUE_FAILED --message-body "{\"stage\":\"rpm-tester\", \"error\":\"$1\", \"yum_repo\":\"$YUM_REPO\", \"commit_hash\":\"$COMMIT_HASH\", \"md5sum\":\"$MD5SUM\", \"rippled_version\":\"$RIPPLED_VERSION\", \"commit_signer\":\"$COMMIT_SIGNER\"}" --region $SQS_REGION
  exit 1
}

RIPPLED_RPM_VERSION=`echo "$RIPPLED_VERSION" | tr - _`

# Check rpm's md5sum
yumdownloader --enablerepo=$YUM_REPO rippled-$RIPPLED_RPM_VERSION
REPO_MD5SUM=`rpm -Kv *.x86_64.rpm | grep 'MD5 digest' | grep -oP '\(\K[^)]+'`
if [ "$REPO_MD5SUM" != "$MD5SUM" ]; then
  error "md5sum mismatch ($REPO_MD5SUM)"
fi

yum install -y --enablerepo=$YUM_REPO rippled-$RIPPLED_RPM_VERSION
rc=$?; if [[ $rc != 0 ]]; then
  error "error downloading rippled-$RIPPLED_RPM_VERSION rpm from $YUM_REPO"
fi

yumdownloader --source --enablerepo=$YUM_REPO rippled-$RIPPLED_RPM_VERSION
rc=$?; if [[ $rc != 0 ]]; then
  error "error downloading rippled-$RIPPLED_RPM_VERSION source rpm from $YUM_REPO"
fi

rpm -i rippled-*.src.rpm
tar -zxf ~/rpmbuild/SOURCES/rippled.tar.gz -C ./
cd rippled
npm install
mkdir build
ln -s /opt/ripple/bin/rippled build/rippled

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/ripple/openssl/lib:/opt/ripple/boost/lib /opt/ripple/bin/rippled --unittest
rc=$?; if [[ $rc != 0 ]]; then
  error "rippled --unittest failed"
fi

LD_LIBRARY_PATH=$LD_LIBRARY_PATH:/opt/ripple/openssl/lib:/opt/ripple/boost/lib npm test
rc=$?; if [[ $rc != 0 ]]; then
  error "npm test failed"
fi

aws sqs send-message --queue-url $SQS_QUEUE_TESTED --message-body "{\"yum_repo\":\"$YUM_REPO\", \"commit_hash\":\"$COMMIT_HASH\", \"md5sum\":\"$MD5SUM\", \"rippled_version\":\"$RIPPLED_VERSION\", \"commit_signer\":\"$COMMIT_SIGNER\"}" --region $SQS_REGION
rc=$?; if [[ $rc != 0 ]]; then
  error "error sending message to $SQS_QUEUE_TESTED"
fi
