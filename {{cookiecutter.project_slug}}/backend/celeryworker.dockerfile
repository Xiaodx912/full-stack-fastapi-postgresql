FROM python:3.9

WORKDIR /app/

COPY ./install_poetry.py /

# Copy poetry.lock* in case it doesn't exist in the repo
COPY ./app/pyproject.toml ./app/poetry.lock* /app/

RUN pip config set global.index-url http://mirrors.aliyun.com/pypi/simple && \
    pip config set install.trusted-host mirrors.aliyun.com && \
    pip install -U pip

# Install Poetry
RUN cat /install_poetry.py | POETRY_HOME=/opt/poetry python && \
    cd /usr/local/bin && \
    ln -s /opt/poetry/bin/poetry && \
    cd /app/ && \
    poetry source add --default mirrors https://pypi.tuna.tsinghua.edu.cn/simple/ && \
    poetry config virtualenvs.create false

# Neomodel has shapely and libgeos as dependencies
RUN sed -i 's/http:\/\/deb.debian.org\/debian/https:\/\/mirrors.tuna.tsinghua.edu.cn\/debian/g' /etc/apt/sources.list && apt-get update && apt-get install -y libgeos-dev

# Allow installing dev dependencies to run tests
ARG INSTALL_DEV=false
RUN bash -c "if [ $INSTALL_DEV == 'true' ] ; then poetry install --no-root ; else poetry install --no-root --no-dev ; fi"

# /start Project-specific dependencies
# RUN apt-get update && apt-get install -y --no-install-recommends \
# && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*	

WORKDIR /app/
# /end Project-specific dependencies	

# For development, Jupyter remote kernel, Hydrogen
# Using inside the container:
# jupyter lab --ip=0.0.0.0 --allow-root --NotebookApp.custom_display_url=http://127.0.0.1:8888
ARG INSTALL_JUPYTER=false
RUN bash -c "if [ $INSTALL_JUPYTER == 'true' ] ; then pip install jupyterlab ; fi"

ENV C_FORCE_ROOT=1
COPY ./app /app
WORKDIR /app
ENV PYTHONPATH=/app
COPY ./app/worker-start.sh /worker-start.sh
RUN chmod +x /worker-start.sh
CMD ["bash", "/worker-start.sh"]
