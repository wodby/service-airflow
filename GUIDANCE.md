# Apache Airflow on Wodby

What Wodby sets up for Airflow on this service. It runs from the official `apache/airflow` image. Configuration is passed as `AIRFLOW__<SECTION>__<KEY>` environment variables, which take precedence over `airflow.cfg`.

## Processes

One pod runs four containers on the same volume: the API server (main container, port 8080, also the web interface), `scheduler`, `dag-processor` and `triggerer`. Before they start, an init container migrates the metadata database (`_AIRFLOW_DB_MIGRATE`) and creates the administrator (`_AIRFLOW_WWW_USER_CREATE`). The executor is `LocalExecutor`: tasks run inside the scheduler container. The service is not scalable.

## Linked services

| Link | Variables |
| --- | --- |
| PostgreSQL (required) | `AIRFLOW__DATABASE__SQL_ALCHEMY_CONN` |

It is the metadata database of Airflow. Do not set the connection elsewhere.

## Generated credentials

| Token | Variable | Use |
| --- | --- | --- |
| `admin_username`, `admin_password` | `_AIRFLOW_WWW_USER_USERNAME`, `_AIRFLOW_WWW_USER_PASSWORD` | administrator created by the init container; an existing user is left as it is |
| `fernet_key` | `AIRFLOW__CORE__FERNET_KEY` | encrypts connection passwords stored in the database |
| `api_secret_key` | `AIRFLOW__API__SECRET_KEY` | API server sessions |
| `api_auth_jwt_secret` | `AIRFLOW__API_AUTH__JWT_SECRET` | tokens between Airflow components and for the API |

Users are managed by the FAB auth manager (`AIRFLOW__CORE__AUTH_MANAGER`). Example DAGs are off (`AIRFLOW__CORE__LOAD_EXAMPLES`).

## Data and DAGs

The `data` volume is mounted at `/opt/airflow`, the Airflow home, in every container. DAG files go to `/opt/airflow/dags` and plugins to `/opt/airflow/plugins`. The service has no build: DAGs are files on the volume, not part of an image.

## Changing configuration

Add or change `AIRFLOW__*` environment variables on the service and deploy it. The scheduler, DAG processor and triggerer are separate containers with their own variables declared in the manifest; after a change, check that it reached the container that uses it.

## Check the result

`/api/v2/monitor/health` on port 8080 reports the state of the metadata database, scheduler, DAG processor and triggerer.
