FROM ubuntu:16.04

# Based on https://github.com/it-projects-llc/install-odoo AND
# https://www.getopenerp.com/install-odoo-10-on-ubuntu-16-04/

# checks if the git url exists.
ARG GIT_ENTERPRISE_URL

RUN echo "GIT directory is:"
RUN echo ${GIT_ENTERPRISE_URL}

#####################
# SET ENV VARIALBES #
#####################
ENV ODOO_BRANCH=10.0 \
    WKHTMLTOPDF_VERSION=0.12.4 \
    WKHTMLTOPDF_CHECKSUM='049b2cdec9a8254f0ef8ac273afaf54f7e25459a273e27189591edc7d7cf29db' \
    OPENERP_SERVER=/mnt/config/odoo-server.conf \
    ODOO_SOURCE_DIR=/mnt/odoo-source \
    ADDONS_DIR=/mnt/addons \
    ADDONS_DIR_ENTERPRISE=/mnt/enterprise \
    BACKUPS_DIR=/mnt/backups \
    LOGS_DIR=/mnt/logs \
    ODOO_DATA_DIR=/mnt/data-dir

####################
# GET DEPENDENCIES #
####################

# Other requirements and recommendations to run Odoo
# See https://github.com/$ODOO_SOURCE/blob/$ODOO_VERSION/debian/control
RUN set -xe;
RUN apt-get update && apt-get -y upgrade

# Install Python Dependencies for Odoo
RUN apt-get install -y python-dateutil python-docutils python-feedparser python-jinja2 python-ldap python-libxslt1 python-lxml python-mako python-mock python-openid python-psycopg2 python-psutil python-pybabel python-pychart python-pydot python-pyparsing python-reportlab python-simplejson python-tz python-unittest2 python-vatnumber python-vobject python-webdav python-werkzeug python-xlwt python-yaml python-zsi poppler-utils python-pip python-pypdf python-passlib python-decorator gcc python-dev mc bzr python-setuptools python-markupsafe python-reportlab-accel python-zsi python-yaml python-argparse python-openssl python-egenix-mxdatetime python-usb python-serial lptools make python-pydot python-psutil python-paramiko poppler-utils python-pdftools antiword python-requests python-xlsxwriter python-suds python-psycogreen python-ofxparse python-gevent git wget curl

# Odoo Web Dependencies
RUN apt-get install -y npm
RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm install -g less less-plugin-clean-css



#####################################
# ODOO SOURCE, USER, DOCKER FOLDERS #
#####################################
RUN git clone --depth=1 -b ${ODOO_BRANCH} https://github.com/odoo/odoo.git $ODOO_SOURCE_DIR && \
    adduser --system --quiet --shell=/bin/bash --home=/opt/odoo --group odoo && \
    chown -R odoo:odoo $ODOO_SOURCE_DIR && \
    mkdir -p $ODOO_SOURCE_DIR && chown odoo $ODOO_SOURCE_DIR && \
    mkdir -p $ADDONS_DIR/extra && chown -R odoo $ADDONS_DIR && \
    mkdir -p $ODOO_DATA_DIR && chown odoo $ODOO_DATA_DIR && \
    mkdir -p /mnt/config && chown odoo /mnt/config && \
    mkdir -p $BACKUPS_DIR && chown odoo $BACKUPS_DIR && \
    mkdir -p $LOGS_DIR && chown odoo $LOGS_DIR

# Checks if we have the odoo enterprise version enabled, if we do, then clone it.
RUN if [ ! -z "$GIT_ENTERPRISE_URL" ]; then  git clone --depth=1 -b ${ODOO_BRANCH} ${GIT_ENTERPRISE_URL} $ADDONS_DIR_ENTERPRISE && chown -R odoo $ADDONS_DIR_ENTERPRISE; fi

# Install wkhtmltox
RUN curl -SLo wkhtmltox.tar.xz https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/${WKHTMLTOPDF_VERSION}/wkhtmltox-${WKHTMLTOPDF_VERSION}_linux-generic-amd64.tar.xz \
    && echo "${WKHTMLTOPDF_CHECKSUM}  wkhtmltox.tar.xz" | sha256sum -c - \
    && tar --strip-components 1 -C /usr/local/ -xf wkhtmltox.tar.xz \
    && rm wkhtmltox.tar.xz \
    && wkhtmltopdf --version

# Install Gdata
RUN cd /opt/odoo
RUN wget https://pypi.python.org/packages/a8/70/bd554151443fe9e89d9a934a7891aaffc63b9cb5c7d608972919a002c03c/gdata-2.0.18.tar.gz
RUN tar zxvf gdata-2.0.18.tar.gz
RUN chown -R odoo: gdata-2.0.18
WORKDIR gdata-2.0.18
RUN python setup.py install


###############################################
# CONFIG, SCRPTS, REPOS, AUTOINSTALL MODULES  #
###############################################
COPY odoo-server.conf $OPENERP_SERVER
COPY odoo-backup.py /usr/local/bin/

RUN apt-get -qq update && \
    chmod +x /usr/local/bin/odoo-backup.py && \
    chown odoo:odoo $OPENERP_SERVER && \
    INIT_ODOO_CONFIG=docker-container \
    UPDATE_ADDONS_PATH=yes

COPY reset-admin-passwords.py /

########################
# DOCKER CONFIGURATION #
########################
COPY ./entrypoint.sh /
EXPOSE 8069 8072
USER odoo
VOLUME ["/mnt/data-dir", \
       "/mnt/backups", \
       "/mnt/logs", \
       "/mnt/addons/extra"]
# /mnt/addons/extra is used for manually added addons.
# Expected structure is:
# /mnt/addons/extra/REPO_OR_GROUP_NAME/MODULE/__openerp__.py
#
# we don't add /mnt/odoo-source, /mnt/addons, /mnt/config to VOLUME in order to allow modify theirs content in inherited dockers

ENTRYPOINT ["/entrypoint.sh"]