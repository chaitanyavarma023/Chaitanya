#!/bin/sh

cmd="$1"

CERTIFICATE_DIR="/etc/chilli"

DEFAULT_SERVER_PEM="${CERTIFICATE_DIR}/server.pem"
DEFAULT_CRT="${CERTIFICATE_DIR}/server.crt"
DEFAULT_KEY="${CERTIFICATE_DIR}/server.key"

UPLOAD_SERVER_PEM="${CERTIFICATE_DIR}/upload.pem"
UPLOAD_CRT_FILE="${CERTIFICATE_DIR}/upload.crt"
UPLOAD_KEY_FILE="${CERTIFICATE_DIR}/upload.key"

TMP_PEM_FILE="/tmp/server.tmp.pem"
TMP_CRT_FILE="/tmp/server.tmp.crt_file"
TMP_KEY_FILE="/tmp/server.tmp.key_file"

seperate_default_file() {

  privateCA_line=`grep -n 'END PRIVATE KEY' ${DEFAULT_SERVER_PEM}  | awk -F':' '{print $1}'`
  sed '1,'${privateCA_line}'d' ${DEFAULT_SERVER_PEM} > $DEFAULT_CRT

  let privateKey_line=privateCA_line+1
  sed ${privateKey_line}',$d' ${DEFAULT_SERVER_PEM} > $DEFAULT_KEY

}

backup_file() {
  # backup default server.pem
  [ ! -s ${DEFAULT_SERVER_PEM} ] && {
    cp ${UPLOAD_SERVER_PEM} ${DEFAULT_SERVER_PEM}
    seperate_default_file
  }
}

delete_files() {
  rm -f /tmp/server.*
}

reset_to_factory() {
  [ -s ${DEFAULT_SERVER_PEM} ] && {
    #Remove cloud & upload certificate
    [ -s ${UPLOAD_SERVER_PEM} ] && rm -f /etc/chilli/upload.*
    [ -s /etc/chilli/cloud.pem ] && rm -rf /etc/chilli/cloud.*
    # Re-generate parsed certificate file for GUI used
    /etc/init.d/chilli restart
    . /usr/sbin/certificate_read.sh
  }
}

if [ "${cmd}" == "reset_factory" ] ; then
  reset_to_factory
else
  backup_file
  [ -s "$TMP_CRT_FILE" -a -s "$TMP_KEY_FILE" ] && {

    # Merge two files
    cat ${TMP_KEY_FILE} > ${TMP_PEM_FILE}
    echo "" > ${TMP_PEM_FILE}
    cat ${TMP_CRT_FILE} >> ${TMP_PEM_FILE}

    # Verify crt
    is_valid_crt=`openssl verify -partial_chain -no_check_time -CAfile $TMP_PEM_FILE $TMP_CRT_FILE | grep "OK"`
    [ -z ${is_valid_crt} ] && {
      delete_files
      return 1
    }

    # Verify key
    is_valid_key=`openssl rsa -noout -check -in $TMP_KEY_FILE | grep "ok"`
    [ -z ${is_valid_key} ] && {
      delete_files
      return 1
    }

    verify1=$(openssl x509 -in $TMP_CRT_FILE -pubkey -noout -outform pem | md5sum)
    verify2=$(openssl pkey -in $TMP_KEY_FILE -pubout -outform pem | md5sum)

    if [ "${verify1}" = "${verify2}" ]; then
      mv ${TMP_CRT_FILE} $UPLOAD_CRT_FILE
      mv ${TMP_KEY_FILE} $UPLOAD_KEY_FILE
      mv ${TMP_PEM_FILE} ${UPLOAD_SERVER_PEM}

      # Re-generate parsed certificate file for GUI used
      /etc/init.d/chilli restart
      . /usr/sbin/certificate_read.sh
    else
      delete_files
      return 1
    fi
  }
fi

delete_files

return 0
