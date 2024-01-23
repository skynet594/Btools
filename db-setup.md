# Postgresql SetUp

- [X] 1. Switch to the “postgres” user, which is the superuser for PostgreSQL

    ```bash
    sudo -u postgres psql
    ```

- [X] 2. Create a new PostgreSQL user with the desired username and password:

    ```bash
    CREATE USER rishii WITH PASSWORD 'rishii';
     ALTER USER rishii WITH SUPERUSER CREATEDB LOGIN PASSWORD 'rishii';
    ```

- [X] 3. To check if the role is created

    ```bash
    \du
    ```

- [X] 3. Lets create the database amass

    ```bash
    create DATABASE amass;
    ALTER DATABASE amass SET TIMEZONE to 'UTC';
    CREATE EXTENSION IF NOT EXISTS pg_trgm;
    ```

    `To see the list of database`

    ```bash
    \l
    ```

    `To see the list of talbe`

    ```bash
    \dt
    ```

- [X] 4. You can access the database with

    ```bash
    psql postgres://rishii:rishii@localhost:5432/amass
    ```

## Note you can change the database name `amass` and the user name `rishii` and password `rishii`
