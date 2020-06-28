#!/usr/bin/env sh

# Available environment variables
#
# ARA_API_PASSWORD
# ARA_API_USERNAME
# ARA_HOST
# ARA_PORT
#
# https://ara.readthedocs.io/en/latest/api-configuration.html#overview

# Set default values

ARA_API_PASSWORD=${ARA_API_PASSWORD:-password}
ARA_API_USERNAME=${ARA_API_USERNAME:-ara}
ARA_HOST=${ARA_HOST:-0.0.0.0}
ARA_PORT=${ARA_PORT:-8000}

until ara-manage migrate; do
    echo "database migration failed, trying again in 10 seconds"
    sleep 10
done

result=$(echo "from django.contrib.auth import get_user_model; User = get_user_model(); print(User.objects.filter(username='$ARA_API_USERNAME').count()>0)" | ara-manage shell | tail -n 1)
if [ $result == "False" ]; then
    echo "from django.contrib.auth.models import User; User.objects.create_superuser('$ARA_API_USERNAME', '$ARA_API_USERNAME@ara-server.local', '$ARA_API_PASSWORD')" | ara-manage shell
fi

exec gunicorn --bind $ARA_HOST:$ARA_PORT ara.server.wsgi
