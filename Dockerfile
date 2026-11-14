# Builds Airflow from the app repository on the apache/airflow image of the
# airflow service's version: the repository's Python packages are installed and
# its DAGs and plugins are added outside /opt/airflow, the data volume, which
# would hide them.
ARG WODBY_BASE_IMAGE
FROM ${WODBY_BASE_IMAGE}

ARG COPY_FROM

COPY --chown=airflow:0 ${COPY_FROM} /opt/airflow-app

ENV AIRFLOW__CORE__DAGS_FOLDER=/opt/airflow-app/dags \
    AIRFLOW__CORE__PLUGINS_FOLDER=/opt/airflow-app/plugins

RUN set -e; \
    mkdir -p /opt/airflow-app/dags /opt/airflow-app/plugins; \
    if [ -f /opt/airflow-app/requirements.txt ]; then \
        # Airflow is pinned, so packages that need another Airflow fail here. \
        pip install --no-cache-dir "apache-airflow==${AIRFLOW_VERSION}" -r /opt/airflow-app/requirements.txt; \
    fi; \
    installed="$(python -c 'import airflow; print(airflow.__version__)')"; \
    if [ "${installed}" != "${AIRFLOW_VERSION}" ]; then \
        echo "requirements.txt changed Airflow from ${AIRFLOW_VERSION} to ${installed}" >&2; \
        exit 1; \
    fi; \
    echo "Airflow ${installed}; DAG files: $(find /opt/airflow-app/dags -name '*.py' | wc -l)"
