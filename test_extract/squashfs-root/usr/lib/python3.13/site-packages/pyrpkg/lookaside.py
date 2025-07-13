# Copyright (c) 2015 - Red Hat Inc.
#
# This program is free software; you can redistribute it and/or modify it
# under the terms of the GNU General Public License as published by the
# Free Software Foundation; either version 2 of the License, or (at your
# option) any later version.  See http://www.gnu.org/copyleft/gpl.html for
# the full text of the license.


"""Interact with a lookaside cache

This module contains everything needed to upload and download source files the
way it is done by Fedora, RHEL, and other distributions maintainers.
"""


import functools
import hashlib
import io
import logging
import os
import sys
import time

import pycurl
import six
from six.moves import http_client, urllib

from .errors import (AlreadyUploadedError, DownloadError, InvalidHashType,
                     UploadError)


class CGILookasideCache(object):
    """A class to interact with a CGI-based lookaside cache"""
    def __init__(self, hashtype, download_url, upload_url,
                 client_cert=None, ca_cert=None, attempts=None, delay=None):
        """Constructor

        :param str hashtype: The hash algorithm to use for uploads. (e.g 'md5')
        :param str download_url: The URL used to download source files.
        :param str upload_url: The URL of the CGI script called when uploading
            source files.
        :param str client_cert: Optional. The full path to the client-side
            certificate to use for HTTPS authentication. It defaults to None,
            in which case no client-side certificate is used.
        :param str ca_cert: Optional. The full path to the CA certificate to
            use for HTTPS connexions. (e.g if the server certificate is
            self-signed. It defaults to None, in which case the system CA
            bundle is used.
        :param int attempts: repeat network operations after failure. The param
            says how many tries to do. None = single attempt / no-retrying
        :param int delay: Initial delay between network operation attempts.
            Each attempt doubles the previous delay value. In seconds.
        """
        self.hashtype = hashtype
        self.download_url = download_url
        self.upload_url = upload_url
        self.client_cert = client_cert
        self.ca_cert = ca_cert
        self.attempts = attempts if attempts is not None and attempts > 1 else 1
        self.delay_between_attempts = delay if delay is not None and delay >= 0 else 15

        self.log = logging.getLogger(__name__)

        self.download_path = '%(name)s/%(filename)s/%(hashtype)s/%(hash)s/%(filename)s'

    def print_progress(self, to_download, downloaded, to_upload, uploaded):
        if not sys.stdout.isatty():
            # Don't print progress if not outputting into TTY. The progress
            # output is not useful in logs.
            return

        if to_download > 0:
            done = downloaded / to_download

        elif to_upload > 0:
            done = uploaded / to_upload

        else:
            return

        done_chars = int(done * 72)
        remain_chars = 72 - done_chars
        done = int(done * 1000) / 10.0

        p = "\r%s%s %s%%" % ("#" * done_chars, " " * remain_chars, done)
        sys.stdout.write(p)
        sys.stdout.flush()

    def hash_file(self, filename, hashtype=None):
        """Compute the hash of a file

        :param str filename: The full path to the file. It is assumed to exist.
        :param str hashtype: Optional. The hash algorithm to use. (e.g 'md5')
            This defaults to the hashtype passed to the constructor.
        :return: The hash digest.
        """
        if hashtype is None:
            hashtype = self.hashtype

        try:
            sum = hashlib.new(hashtype)

        except ValueError:
            raise InvalidHashType(hashtype)

        with open(filename, 'rb') as f:
            chunk = f.read(8192)

            while chunk:
                sum.update(chunk)
                chunk = f.read(8192)

        return sum.hexdigest()

    def file_is_valid(self, filename, hash, hashtype=None):
        """Ensure the file is correct

        :param str filename: The full path to the file. It is assumed to exist.
        :param str hash: The known good hash of the file.
        :param str hashtype: Optional. The hash algorithm to use. (e.g 'md5')
            This defaults to the hashtype passed to the constructor.
        :return: True if the file is valid, False otherwise.
        :rtype: bool
        """
        sum = self.hash_file(filename, hashtype)
        return sum == hash

    def raise_upload_error(self, http_status):
        messages = {
            http_client.UNAUTHORIZED: 'Dist-git request is unauthorized.',
            http_client.INTERNAL_SERVER_ERROR: 'Error occurs inside the server.',
        }
        default = 'Fail to upload files. Server returns status {0}'.format(http_status)
        message = messages.get(http_status, default)
        raise UploadError(message, http_status=http_status)

    def get_download_url(self, name, filename, hash, hashtype=None, **kwargs):
        path_dict = {'name': name, 'filename': filename,
                     'hash': hash, 'hashtype': hashtype}
        path_dict.update(kwargs)
        path = self.download_path % path_dict
        return os.path.join(self.download_url, path)

    def download(self, name, filename, hash, outfile, hashtype=None, **kwargs):
        """Download a source file

        :param str name: The name of the module. (usually the name of the
            SRPM). This can include the namespace as well (depending on what
            the server side expects).
        :param str filename: The name of the file to download.
        :param str hash: The known good hash of the file.
        :param str outfile: The full path where to save the downloaded file.
        :param str hashtype: Optional. The hash algorithm. (e.g 'md5') This
            defaults to the hashtype passed to the constructor.
        :param kwargs: Additional keyword arguments. They will be used when
            constructing the full URL to the file to download.
        """
        if hashtype is None:
            hashtype = self.hashtype

        if os.path.exists(outfile):
            if self.file_is_valid(outfile, hash, hashtype=hashtype):
                self.log.info("Not downloading already downloaded %s" % filename)
                return

        self.log.info("Downloading %s from %s", filename, self.download_url)
        urled_file = urllib.parse.quote(filename)
        url = self.get_download_url(name, urled_file, hash, hashtype, **kwargs)
        if six.PY2 and isinstance(url, six.text_type):
            url = url.encode('utf-8')
        self.log.debug("Full url: %s", url)

        c = pycurl.Curl()
        c.setopt(pycurl.URL, url)
        c.setopt(pycurl.HTTPHEADER, ['Pragma:'])
        c.setopt(pycurl.NOPROGRESS, False)
        c.setopt(pycurl.PROGRESSFUNCTION, self.print_progress)
        c.setopt(pycurl.OPT_FILETIME, True)
        c.setopt(pycurl.LOW_SPEED_LIMIT, 1000)
        c.setopt(pycurl.LOW_SPEED_TIME, 60)
        c.setopt(pycurl.FOLLOWLOCATION, 1)

        # call retry method directly instead of @retry decorator - this approach allows passing
        # object's internal variables into the retry method
        status, tstamp = self.retry(raises=DownloadError)(self.retry_download)(c, outfile)
        c.close()

        # Get back a new line, after displaying the download progress
        if sys.stdout.isatty():
            sys.stdout.write('\n')
            sys.stdout.flush()

        if status != 200:
            self.log.info('Remove downloaded invalid file %s', outfile)
            os.remove(outfile)
            raise DownloadError('Dist-git server returned status code %d' % status)

        os.utime(outfile, (tstamp, tstamp))

        if not self.file_is_valid(outfile, hash, hashtype=hashtype):
            raise DownloadError('%s failed checksum' % filename)

    def remote_file_exists_head(self, name, filename, hash, hashtype):
        """Verify whether a file exists on the lookaside cache.
        Uses a HTTP HEAD request and doesn't require authentication.

        :param str name: The name of the module. (usually the name of the
            SRPM). This can include the namespace as well (depending on what
            the server side expects).
        :param str filename: The name of the file to check for.
        :param str hash: The known good hash of the file.
        :param str hashtype: The type of hash
        """

        urled_file = urllib.parse.quote(filename)
        url = self.get_download_url(name, urled_file, hash, hashtype or self.hashtype)
        if six.PY2 and isinstance(url, six.text_type):
            url = url.encode('utf-8')

        c = pycurl.Curl()
        c.setopt(pycurl.URL, url)
        c.setopt(pycurl.NOBODY, True)
        c.setopt(pycurl.FOLLOWLOCATION, 1)

        status = self.retry(raises=DownloadError)(self.retry_remote_file_exists_head)(c)
        c.close()

        if status != 200:
            self.log.debug('Unavailable file \'%s\' at %s' % (filename, url))
            return False
        return True

    def remote_file_exists(self, name, filename, hash):
        """Verify whether a file exists on the lookaside cache

        :param str name: The name of the module. (usually the name of the
            SRPM). This can include the namespace as well (depending on what
            the server side expects).
        :param str filename: The name of the file to check for.
        :param str hash: The known good hash of the file.
        """

        # RHEL 7 ships pycurl that does not accept unicode. When given unicode
        # type it would explode with "unsupported second type in tuple". Let's
        # convert to str just to be sure.
        # https://bugzilla.redhat.com/show_bug.cgi?id=1241059
        if six.PY2 and isinstance(filename, six.text_type):
            filename = filename.encode('utf-8')

        post_data = [('name', name),
                     ('%ssum' % self.hashtype, hash),
                     ('filename', filename)]

        c = pycurl.Curl()
        c.setopt(pycurl.URL, self.upload_url)
        c.setopt(pycurl.HTTPPOST, post_data)
        c.setopt(pycurl.FOLLOWLOCATION, 1)

        if self.client_cert is not None:
            if os.path.exists(self.client_cert):
                c.setopt(pycurl.SSLCERT, self.client_cert)
            else:
                self.log.warning("Missing certificate: %s"
                                 % self.client_cert)

        if self.ca_cert is not None:
            if os.path.exists(self.ca_cert):
                c.setopt(pycurl.CAINFO, self.ca_cert)
            else:
                self.log.warning("Missing certificate: %s", self.ca_cert)

        c.setopt(pycurl.HTTPAUTH, pycurl.HTTPAUTH_GSSNEGOTIATE)
        c.setopt(pycurl.USERPWD, ':')

        status, output = self.retry(raises=UploadError)(self.retry_remote_file_exists)(c)
        c.close()

        if status != 200:
            self.raise_upload_error(status)
        self.log.debug("%s returned status %d", self.upload_url, status)

        # Lookaside CGI script returns these strings depending on whether
        # or not the file exists:
        if output == b'Available':
            return True

        if output == b'Missing':
            return False

        if output == b'Required checksum is not present':
            return False

        # Something unexpected happened
        self.log.debug(output)
        raise UploadError('Error checking for %s at %s'
                          % (filename, self.upload_url))

    def upload(self, name, filepath, hash, offline=False):
        """Upload a source file

        :param str name: The name of the module. (usually the name of the SRPM)
            This can include the namespace as well (depending on what the
            server side expects).
        :param str filepath: The full path to the file to upload.
        :param str hash: The known good hash of the file.
        :param bool offline: Method prints a message about disabled upload and does return.
        """
        self.log.info("Uploading: %s to %s", filepath, self.upload_url)
        if offline:
            self.log.info("*Upload disabled*")
            return

        filename = os.path.basename(filepath)

        # As in remote_file_exists, we need to convert unicode strings to str
        if six.PY2:
            if isinstance(name, six.text_type):
                name = name.encode('utf-8')
            if isinstance(filepath, six.text_type):
                filepath = filepath.encode('utf-8')

        if self.remote_file_exists(name, filename, hash):
            self.log.info("File already uploaded: %s", filepath)
            raise AlreadyUploadedError('File already uploaded')

        self.log.info("Uploading: %s", filepath)
        post_data = [
            ('name', name),
            ('%ssum' % self.hashtype, hash),
            ('file', (pycurl.FORM_FILE, filepath)),
            ('mtime', str(int(os.stat(filepath).st_mtime))),
        ]

        c = pycurl.Curl()
        c.setopt(pycurl.URL, self.upload_url)
        c.setopt(pycurl.NOPROGRESS, False)
        c.setopt(pycurl.PROGRESSFUNCTION, self.print_progress)
        c.setopt(pycurl.HTTPPOST, post_data)
        c.setopt(pycurl.FOLLOWLOCATION, 1)

        if self.client_cert is not None:
            if os.path.exists(self.client_cert):
                c.setopt(pycurl.SSLCERT, self.client_cert)
            else:
                self.log.warning("Missing certificate: %s", self.client_cert)

        if self.ca_cert is not None:
            if os.path.exists(self.ca_cert):
                c.setopt(pycurl.CAINFO, self.ca_cert)
            else:
                self.log.warning("Missing certificate: %s", self.ca_cert)

        c.setopt(pycurl.HTTPAUTH, pycurl.HTTPAUTH_GSSNEGOTIATE)
        c.setopt(pycurl.USERPWD, ':')

        status, output = self.retry(raises=UploadError)(self.retry_upload)(c)
        c.close()

        # Get back a new line, after displaying the download progress
        if sys.stdout.isatty():
            sys.stdout.write('\n')
            sys.stdout.flush()

        if status != 200:
            self.raise_upload_error(status)

        if output:
            self.log.debug(output)

    def retry_download(self, curl, outfile):
        with open(outfile, 'wb') as f:
            curl.setopt(pycurl.WRITEDATA, f)
            curl.perform()
            tstamp = curl.getinfo(pycurl.INFO_FILETIME)
            status = curl.getinfo(pycurl.RESPONSE_CODE)
        return status, tstamp

    def retry_remote_file_exists_head(self, curl):
        curl.perform()
        status = curl.getinfo(pycurl.RESPONSE_CODE)
        return status

    def retry_remote_file_exists(self, curl):
        with io.BytesIO() as buf:
            curl.setopt(pycurl.WRITEFUNCTION, buf.write)
            curl.perform()
            status = curl.getinfo(pycurl.RESPONSE_CODE)
            output = buf.getvalue().strip()
        return status, output

    def retry_upload(self, curl):
        with io.BytesIO() as buf:
            curl.setopt(pycurl.WRITEFUNCTION, buf.write)
            curl.perform()
            status = curl.getinfo(pycurl.RESPONSE_CODE)
            output = buf.getvalue().strip()
        return status, output

    def retry(self, attempts=None, delay_between_attempts=None, wait_on=pycurl.error, raises=None):
        """A decorator that allows to retry a section of code until success or counter elapses
        """

        def wrapper(function):
            @functools.wraps(function)
            def inner(*args, **kwargs):

                attempts_all = attempts or self.attempts
                attempts_left = attempts_all
                delay = delay_between_attempts or self.delay_between_attempts
                while attempts_left > 0:
                    try:
                        return function(*args, **kwargs)
                    except wait_on as e:
                        self.log.warning("Network error: %s" % (e))
                        attempts_left -= 1
                        self.log.debug("Attempt %d/%d has failed."
                                       % (attempts_all - attempts_left, attempts_all))
                        if attempts_left:
                            self.log.info("The operation will be retried in %ds." % (delay))
                            time.sleep(delay)
                            delay *= 2
                            self.log.info("Retrying ...")
                        else:
                            if raises is None:
                                raise  # This re-raises the last exception.
                            else:
                                raise raises(e)

            return inner

        return wrapper
