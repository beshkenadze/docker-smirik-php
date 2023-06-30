#!/bin/sh
# sh bin/genkeys.sh

if [ "$APP_ENV" != 'prod' ]; then
    composer install --prefer-dist --no-progress --no-interaction
fi

if grep -q DATABASE_URL= .env; then
    echo "Waiting for database to be ready..."
    ATTEMPTS_LEFT_TO_REACH_DATABASE=60
    until [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ] || DATABASE_ERROR=$(php bin/console dbal:run-sql -q "SELECT 1" 2>&1); do
        if [ $? -eq 255 ]; then
            # If the Doctrine command exits with 255, an unrecoverable error occurred
            ATTEMPTS_LEFT_TO_REACH_DATABASE=0
            break
        fi
        sleep 1
        ATTEMPTS_LEFT_TO_REACH_DATABASE=$((ATTEMPTS_LEFT_TO_REACH_DATABASE - 1))
        echo "Still waiting for database to be ready... Or maybe the database is not reachable. $ATTEMPTS_LEFT_TO_REACH_DATABASE attempts left."
    done

    if [ $ATTEMPTS_LEFT_TO_REACH_DATABASE -eq 0 ]; then
        echo "The database is not up or not reachable:"
        echo "$DATABASE_ERROR"
        exit 1
    else
        echo "The database is now ready and reachable"
    fi

    if ls -A migrations/*.php >/dev/null 2>&1; then
        php bin/console doctrine:migrations:migrate --no-interaction
    fi

    # echo "Setting up the jwt keys..."
    # ./bin/genkeys.sh

    echo "Setting up the permissions for the uploads directory..."
    mkdir -p public/uploads
    chmod -R 760 public/uploads
    chown -R nobody:nobody public/uploads
fi
