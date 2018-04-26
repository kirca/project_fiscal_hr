# Copyright (C) 2016-2018 Lambda IS DOOEL

FROM ubuntu:14.04

# All packages needed for running odoo
RUN apt-get update && apt-get -y -q install \
    build-essential \
    python-dev \
    python-pip \
    libpq-dev \
    libfreetype6-dev \
    libxml2-dev \
    libxslt1-dev \
    libjpeg62-dev \
    liblcms1-dev \
    libpng12-dev \
    libsasl2-dev \
    libssl-dev \
    libldap2-dev \
    fontconfig \
    libfontconfig1 \
    libjpeg-turbo8 \
    libxrender1 \
    xfonts-base \
    xfonts-75dpi \
    ca-certificates \
    git \
    wget \
    curl \
    socat \
    npm \
    unzip \
    vim && rm -rf /var/lib/apt/lists/*

RUN echo "deb http://apt.postgresql.org/pub/repos/apt/ trusty-pgdg main 9.5" >> /etc/apt/sources.list.d/postgresql.list && \
    wget --quiet -O - https://www.postgresql.org/media/keys/ACCC4CF8.asc | apt-key add - && \
    apt-get update && \
    apt-get -y -q install postgresql-client-9.5 && rm -rf /var/lib/apt/lists/*

RUN gpg --keyserver hkp://p80.pool.sks-keyservers.net:80 --recv-keys B42F6819007F00F88E364FD4036A9C25BF357DD4
RUN wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture)" \
    && wget -O /usr/local/bin/gosu.asc "https://github.com/tianon/gosu/releases/download/1.2/gosu-$(dpkg --print-architecture).asc" \
    && gpg --verify /usr/local/bin/gosu.asc \
    && rm /usr/local/bin/gosu.asc \
    && chmod +x /usr/local/bin/gosu

RUN ln -s /usr/bin/nodejs /usr/bin/node
RUN npm config set strict-ssl false
RUN npm install -g less less-plugin-clean-css

RUN wget https://github.com/wkhtmltopdf/wkhtmltopdf/releases/download/0.12.1/wkhtmltox-0.12.1_linux-trusty-amd64.deb && \
    dpkg -i wkhtmltox-0.12.1_linux-trusty-amd64.deb && rm wkhtmltox-0.12.1_linux-trusty-amd64.deb

RUN useradd --system -m -r -U odoo && \
    echo "odoo ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

ENV HOME=/home/odoo \
    ODOO_COMMIT=515a5ed900194050930d27d06f237a7c2e627354

WORKDIR $HOME
RUN wget -O odoo.zip https://github.com/odoo/odoo/archive/$ODOO_COMMIT.zip && \
    unzip -q odoo.zip && \
    mv odoo-$ODOO_COMMIT odoo && \
    rm odoo.zip && \
    chown -R odoo:odoo odoo

RUN pip install --upgrade pip setuptools
RUN pip install virtualenv
RUN virtualenv $HOME/odooenv
RUN $HOME/odooenv/bin/pip install -r odoo/requirements.txt

RUN mkdir -p $HOME/project_fiscal_hr
COPY . $HOME/project_fiscal_hr

RUN cp $HOME/project_fiscal_hr/odoo.sh / && \
    chmod 777 /odoo.sh

WORKDIR $HOME/odoo

RUN git apply $HOME/project_fiscal_hr/pos_validate_wait/pos_print_receipt_after_order_processed.patch

ENV PGHOST=db \
    PGPORT=5432 \
    PGDATABASE=odoo \
    PGUSER=odoo \
    DB_TEMPLATE=template1 \
    LOG_LEVEL=critical

RUN chown -R odoo:odoo $HOME

EXPOSE 8069
ENTRYPOINT ["/odoo.sh"]
